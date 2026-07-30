package com.fittrack.auth.service;

import com.fittrack.auth.entity.UserAuthToken;
import com.fittrack.auth.repository.UserAuthTokenRepository;
import com.fittrack.user.entity.User;
import lombok.RequiredArgsConstructor;
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

    private final UserAuthTokenRepository tokenRepository;
    private final PasswordEncoder passwordEncoder;
    private final SecureRandom secureRandom = new SecureRandom();

    @Transactional
    public String createEmailVerificationToken(User user) {
        return create(user, EMAIL_VERIFICATION, 30);
    }

    @Transactional
    public String createPasswordResetToken(User user) {
        return create(user, PASSWORD_RESET, 15);
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
        token.setUsedAt(LocalDateTime.now());
    }

    private String create(User user, String type, int validityMinutes) {
        tokenRepository.deleteByUserAndTypeAndUsedAtIsNull(user, type);

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
