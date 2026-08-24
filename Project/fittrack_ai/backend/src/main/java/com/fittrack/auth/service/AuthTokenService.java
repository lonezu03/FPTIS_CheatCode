package com.fittrack.auth.service;

import com.fittrack.auth.entity.UserAuthToken;
import com.fittrack.auth.repository.UserAuthTokenRepository;
import com.fittrack.user.entity.User;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.time.LocalDateTime;
import java.util.Base64;
import java.util.HexFormat;

@Service
@RequiredArgsConstructor
public class AuthTokenService {

    public static final String EMAIL_VERIFICATION = "EMAIL_VERIFICATION";
    public static final String PASSWORD_RESET = "PASSWORD_RESET";
    public static final String PASSWORD_RESET_OTP = "PASSWORD_RESET_OTP";
    public static final String REFRESH = "REFRESH";

    private final UserAuthTokenRepository tokenRepository;
    private final PasswordEncoder passwordEncoder;
    private final SecureRandom secureRandom = new SecureRandom();

    @Value("${app.jwt.refresh-expiration-days:30}")
    private int refreshExpirationDays;

    @Transactional
    public String createEmailVerificationToken(User user) {
        return create(user, EMAIL_VERIFICATION, 30);
    }

    @Transactional
    public String createPasswordResetToken(User user) {
        return create(user, PASSWORD_RESET, 15);
    }

    @Transactional
    public String createPasswordResetOtp(User user) {
        tokenRepository.deleteByUserAndTypeAndUsedAtIsNull(user, PASSWORD_RESET_OTP);
        String otp = String.format("%06d", secureRandom.nextInt(1_000_000));
        tokenRepository.save(UserAuthToken.builder()
                .user(user)
                .tokenHash(passwordEncoder.encode(otp))
                .type(PASSWORD_RESET_OTP)
                .expiresAt(LocalDateTime.now().plusMinutes(10))
                .failedAttempts(0)
                .build());
        return otp;
    }

    @Transactional
    public String createRefreshToken(User user) {
        return create(user, REFRESH, refreshExpirationDays * 24 * 60, false);
    }

    @Transactional
    public RotatedRefreshToken rotateRefreshToken(String rawToken) {
        UserAuthToken current = getValidForUpdate(rawToken, REFRESH);
        current.setUsedAt(LocalDateTime.now());
        return new RotatedRefreshToken(
                current.getUser(),
                create(current.getUser(), REFRESH, refreshExpirationDays * 24 * 60, false)
        );
    }

    @Transactional
    public void revokeRefreshToken(String rawToken) {
        if (rawToken == null || rawToken.isBlank()) {
            return;
        }
        tokenRepository.findValidForUpdate(hash(rawToken), REFRESH)
                .ifPresent(token -> token.setUsedAt(LocalDateTime.now()));
    }

    @Transactional
    public void revokeAllSessions(User user) {
        tokenRepository.deleteByUserAndTypeAndUsedAtIsNull(user, REFRESH);
        user.setTokenVersion((user.getTokenVersion() == null ? 0L : user.getTokenVersion()) + 1L);
    }

    @Transactional
    public void verifyEmail(String rawToken) {
        UserAuthToken token = getValid(rawToken, EMAIL_VERIFICATION);
        token.getUser().setEmailVerified(true);
        token.setUsedAt(LocalDateTime.now());
    }

    @Transactional
    public void resetPassword(String rawToken, String newPassword) {
        UserAuthToken token = getValid(rawToken, PASSWORD_RESET);
        token.getUser().setPassword(passwordEncoder.encode(newPassword));
        token.getUser().setPasswordChangeRequired(false);
        revokeAllSessions(token.getUser());
        token.setUsedAt(LocalDateTime.now());
    }

    @Transactional(noRollbackFor = InvalidOtpException.class)
    public void resetPasswordWithOtp(User user, String rawOtp, String newPassword) {
        UserAuthToken token = tokenRepository
                .findFirstByUserAndTypeAndUsedAtIsNullOrderByCreatedAtDesc(
                        user,
                        PASSWORD_RESET_OTP
                )
                .orElseThrow(() -> new InvalidOtpException(
                        "Email hoặc mã OTP không hợp lệ"
                ));
        LocalDateTime now = LocalDateTime.now();
        if (token.getExpiresAt().isBefore(now)) {
            token.setUsedAt(now);
            throw new InvalidOtpException(
                    "Mã OTP đã hết hạn. Vui lòng yêu cầu mã mới"
            );
        }
        int failedAttempts = token.getFailedAttempts() == null
                ? 0
                : token.getFailedAttempts();
        if (failedAttempts >= 5) {
            token.setUsedAt(now);
            throw new InvalidOtpException(
                    "Mã OTP đã bị khóa. Vui lòng yêu cầu mã mới"
            );
        }
        if (!passwordEncoder.matches(rawOtp, token.getTokenHash())) {
            int nextAttempts = failedAttempts + 1;
            token.setFailedAttempts(nextAttempts);
            if (nextAttempts >= 5) {
                token.setUsedAt(now);
            }
            throw new InvalidOtpException(
                    nextAttempts >= 5
                            ? "Mã OTP đã bị khóa. Vui lòng yêu cầu mã mới"
                            : "Email hoặc mã OTP không hợp lệ"
            );
        }

        token.getUser().setPassword(passwordEncoder.encode(newPassword));
        token.getUser().setPasswordChangeRequired(false);
        token.setUsedAt(now);
        revokeAllSessions(token.getUser());
    }

    private String create(User user, String type, int validityMinutes) {
        return create(user, type, validityMinutes, true);
    }

    private String create(
            User user,
            String type,
            int validityMinutes,
            boolean replaceExisting
    ) {
        if (replaceExisting) {
            tokenRepository.deleteByUserAndTypeAndUsedAtIsNull(user, type);
        }

        byte[] bytes = new byte[32];
        secureRandom.nextBytes(bytes);
        String rawToken = Base64.getUrlEncoder()
                .withoutPadding()
                .encodeToString(bytes);
        tokenRepository.save(UserAuthToken.builder()
                .user(user)
                .tokenHash(hash(rawToken))
                .type(type)
                .expiresAt(LocalDateTime.now().plusMinutes(validityMinutes))
                .build());
        return rawToken;
    }

    private UserAuthToken getValid(String rawToken, String type) {
        UserAuthToken token = tokenRepository
                .findByTokenHashAndTypeAndUsedAtIsNull(hash(rawToken), type)
                .orElseThrow(() -> new IllegalArgumentException(
                        "Liên kết không hợp lệ hoặc đã được sử dụng"
                ));
        if (token.getExpiresAt().isBefore(LocalDateTime.now())) {
            throw new IllegalArgumentException(
                    "Liên kết đã hết hạn, vui lòng yêu cầu liên kết mới"
            );
        }
        return token;
    }

    private UserAuthToken getValidForUpdate(String rawToken, String type) {
        UserAuthToken token = tokenRepository
                .findValidForUpdate(hash(rawToken), type)
                .orElseThrow(() -> new IllegalArgumentException(
                        "Phiên đăng nhập không hợp lệ hoặc đã được sử dụng"
                ));
        if (token.getExpiresAt().isBefore(LocalDateTime.now())) {
            throw new IllegalArgumentException(
                    "Phiên đăng nhập đã hết hạn, vui lòng đăng nhập lại"
            );
        }
        return token;
    }

    public record RotatedRefreshToken(User user, String rawToken) {
    }

    private static final class InvalidOtpException extends IllegalArgumentException {
        private InvalidOtpException(String message) {
            super(message);
        }
    }

    private String hash(String value) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            return HexFormat.of().formatHex(
                    digest.digest(value.getBytes(StandardCharsets.UTF_8))
            );
        } catch (NoSuchAlgorithmException exception) {
            throw new IllegalStateException(
                    "Không thể tạo mã xác thực an toàn",
                    exception
            );
        }
    }
}
