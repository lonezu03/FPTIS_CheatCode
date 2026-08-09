package com.fittrack.auth.service;

import com.fittrack.auth.dto.AuthResponse;
import com.fittrack.auth.dto.AuthFlowDtos.RegistrationResponse;
import com.fittrack.auth.dto.LoginRequest;
import com.fittrack.auth.dto.RegisterRequest;
import com.fittrack.auth.exception.EmailVerificationRequiredException;
import com.fittrack.common.exception.ConflictException;
import com.fittrack.common.exception.ServiceUnavailableException;
import com.fittrack.common.security.JwtService;
import com.fittrack.user.entity.User;
import com.fittrack.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Locale;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final AuthTokenService authTokenService;
    private final ApplicationMailService mailService;

    @Value("${app.mail.registration-requires-email:false}")
    private boolean registrationRequiresEmail;

    @Transactional
    public RegistrationResponse register(RegisterRequest request) {
        String email = normalizeEmail(request.getEmail());
        if (userRepository.existsByEmail(email)) {
            throw new ConflictException("Email đã được sử dụng");
        }

        if (registrationRequiresEmail && !mailService.isEnabled()) {
            throw new ServiceUnavailableException(
                    "Đăng ký tạm thời đóng vì dịch vụ xác thực email chưa được cấu hình"
            );
        }
        boolean verificationRequired = mailService.isEnabled();
        User user = User.builder()
                .email(email)
                .password(passwordEncoder.encode(request.getPassword()))
                .fullName(request.getFullName())
                .gender(request.getGender())
                .age(request.getAge())
                .height(request.getHeight())
                .weight(request.getWeight())
                .goal(request.getGoal())
                .activityLevel(request.getActivityLevel())
                .role("USER")
                .lunchEnabled(true)
                .fitnessEnabled(false)
                .healthEnabled(false)
                .chatbotEnabled(false)
                .emailVerified(!verificationRequired)
                .build();

        User savedUser = userRepository.save(user);
        boolean sent = false;
        if (verificationRequired) {
            String rawToken =
                    authTokenService.createEmailVerificationToken(savedUser);
            sent = mailService.sendVerificationEmail(
                    savedUser.getEmail(),
                    savedUser.getFullName(),
                    rawToken
            );
        }

        String message;
        if (!verificationRequired) {
            message = "Đăng ký thành công. Bạn có thể đăng nhập ngay.";
        } else if (sent) {
            message = "Đăng ký thành công. Vui lòng kiểm tra email để xác thực tài khoản.";
        } else {
            message = "Đăng ký thành công nhưng chưa gửi được email. "
                    + "Hãy dùng chức năng gửi lại email xác thực.";
        }

        return new RegistrationResponse(
                savedUser.getEmail(),
                message,
                verificationRequired,
                sent
        );
    }

    @Transactional
    public AuthSession login(LoginRequest request) {
        User user = userRepository.findByEmail(normalizeEmail(request.getEmail()))
                .orElseThrow(() -> new BadCredentialsException("Invalid email or password"));

        if (!Boolean.TRUE.equals(user.getActive())) {
            throw new BadCredentialsException("Invalid email or password");
        }

        if (!Boolean.TRUE.equals(user.getEmailVerified())) {
            throw new EmailVerificationRequiredException(
                    "Email chưa được xác thực. Vui lòng kiểm tra hộp thư hoặc gửi lại email xác thực."
            );
        }

        boolean passwordMatches = passwordEncoder.matches(
                request.getPassword(),
                user.getPassword()
        );

        if (!passwordMatches) {
            throw new BadCredentialsException("Invalid email or password");
        }

        if ("ADMIN".equalsIgnoreCase(user.getRole())
                && "123456".equals(request.getPassword())) {
            user.setPasswordChangeRequired(true);
        }

        String token = jwtService.generateToken(user);
        String refreshToken = authTokenService.createRefreshToken(user);

        return new AuthSession(buildAuthResponse(user, token), refreshToken);
    }

    @Transactional
    public AuthSession refresh(String rawRefreshToken) {
        AuthTokenService.RotatedRefreshToken rotated =
                authTokenService.rotateRefreshToken(rawRefreshToken);
        User user = rotated.user();
        if (!Boolean.TRUE.equals(user.getActive())) {
            throw new BadCredentialsException("Invalid refresh token");
        }
        return new AuthSession(
                buildAuthResponse(user, jwtService.generateToken(user)),
                rotated.rawToken()
        );
    }

    @Transactional
    public AuthSession changePassword(
            User user,
            com.fittrack.auth.dto.AuthFlowDtos.ChangePasswordRequest request
    ) {
        User managedUser = userRepository.findByIdForUpdate(user.getId())
                .filter(candidate -> Boolean.TRUE.equals(candidate.getActive()))
                .orElseThrow(() -> new BadCredentialsException("Tài khoản không còn khả dụng"));

        if (!passwordEncoder.matches(request.currentPassword(), managedUser.getPassword())) {
            throw new BadCredentialsException("Mật khẩu hiện tại không chính xác");
        }
        if (passwordEncoder.matches(request.newPassword(), managedUser.getPassword())) {
            throw new IllegalArgumentException("Mật khẩu mới phải khác mật khẩu hiện tại");
        }
        managedUser.setPassword(passwordEncoder.encode(request.newPassword()));
        managedUser.setPasswordChangeRequired(false);
        authTokenService.revokeAllSessions(managedUser);
        return new AuthSession(
                buildAuthResponse(managedUser, jwtService.generateToken(managedUser)),
                authTokenService.createRefreshToken(managedUser)
        );
    }

    @Transactional
    public void logout(String refreshToken) {
        authTokenService.revokeRefreshToken(refreshToken);
    }

    private AuthResponse buildAuthResponse(User user, String token) {
        return AuthResponse.builder()
                .token(token)
                .tokenType("Bearer")
                .userId(user.getId())
                .email(user.getEmail())
                .fullName(user.getFullName())
                .role(user.getRole())
                .lunchEnabled(Boolean.TRUE.equals(user.getLunchEnabled()))
                .fitnessEnabled(Boolean.TRUE.equals(user.getFitnessEnabled()))
                .healthEnabled(Boolean.TRUE.equals(user.getHealthEnabled()))
                .chatbotEnabled(Boolean.TRUE.equals(user.getChatbotEnabled()))
                .passwordChangeRequired(Boolean.TRUE.equals(user.getPasswordChangeRequired()))
                .build();
    }

    public record AuthSession(AuthResponse response, String refreshToken) {
    }

    private String normalizeEmail(String email) {
        return email == null
                ? ""
                : email.trim().toLowerCase(Locale.ROOT);
    }

}
