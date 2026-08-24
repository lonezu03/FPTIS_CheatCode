package com.fittrack.auth.controller;

import com.fittrack.auth.dto.AuthResponse;
import com.fittrack.auth.dto.AuthFlowDtos.*;
import com.fittrack.auth.dto.LoginRequest;
import com.fittrack.auth.dto.RegisterRequest;
import com.fittrack.auth.service.AuthService;
import com.fittrack.auth.service.AuthTokenService;
import com.fittrack.auth.service.ApplicationMailService;
import com.fittrack.auth.service.AuthCookieService;
import com.fittrack.auth.service.AuthRateLimitService;
import com.fittrack.common.exception.ServiceUnavailableException;
import com.fittrack.user.entity.User;
import com.fittrack.user.repository.UserRepository;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.time.Duration;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;
    private final AuthTokenService authTokenService;
    private final ApplicationMailService mailService;
    private final UserRepository userRepository;
    private final AuthCookieService cookieService;
    private final AuthRateLimitService rateLimitService;

    @PostMapping("/register")
    public RegistrationResponse register(
            @Valid @RequestBody RegisterRequest request,
            HttpServletRequest servletRequest
    ) {
        rateLimitService.check(
                "register", clientAddress(servletRequest), request.getEmail(),
                5, Duration.ofHours(1)
        );
        return authService.register(request);
    }

    @PostMapping("/login")
    public AuthResponse login(
            @Valid @RequestBody LoginRequest request,
            HttpServletRequest servletRequest,
            HttpServletResponse servletResponse
    ) {
        rateLimitService.check(
                "login", clientAddress(servletRequest), request.getEmail(),
                10, Duration.ofMinutes(15)
        );
        AuthService.AuthSession session = authService.login(request);
        cookieService.writeSession(servletResponse, session);
        return session.response();
    }

    @PostMapping("/refresh")
    public AuthResponse refresh(
            @RequestBody(required = false) RefreshRequest request,
            HttpServletRequest servletRequest,
            HttpServletResponse servletResponse
    ) {
        rateLimitService.check(
                "refresh", clientAddress(servletRequest), "session",
                30, Duration.ofMinutes(5)
        );
        String rawToken = cookieService.readRefreshToken(servletRequest);
        if ((rawToken == null || rawToken.isBlank()) && request != null) {
            rawToken = request.refreshToken();
        }
        if (rawToken == null || rawToken.isBlank()) {
            throw new IllegalArgumentException("Phiên đăng nhập không tồn tại");
        }
        AuthService.AuthSession session = authService.refresh(rawToken);
        cookieService.writeSession(servletResponse, session);
        return session.response();
    }

    @PostMapping("/logout")
    public MessageResponse logout(
            HttpServletRequest servletRequest,
            HttpServletResponse servletResponse
    ) {
        authService.logout(cookieService.readRefreshToken(servletRequest));
        cookieService.clearSession(servletResponse);
        return new MessageResponse("Đã đăng xuất");
    }

    @PostMapping("/change-password")
    public AuthResponse changePassword(
            Authentication authentication,
            @Valid @RequestBody ChangePasswordRequest request,
            HttpServletResponse servletResponse
    ) {
        AuthService.AuthSession session = authService.changePassword(
                (User) authentication.getPrincipal(), request
        );
        cookieService.writeSession(servletResponse, session);
        return session.response();
    }

    @PostMapping("/verify-email")
    public MessageResponse verifyEmail(
            @Valid @RequestBody TokenRequest request
    ) {
        authTokenService.verifyEmail(request.token());
        return new MessageResponse(
                "Xác thực email thành công. Bạn có thể đăng nhập."
        );
    }

    @PostMapping("/resend-verification")
    public MessageResponse resendVerification(
            @Valid @RequestBody EmailRequest request,
            HttpServletRequest servletRequest
    ) {
        if (!mailService.isConfigured()) {
            throw new ServiceUnavailableException(
                    "Dịch vụ email chưa được cấu hình. Vui lòng liên hệ quản trị viên"
            );
        }
        rateLimitService.check(
                "resend", clientAddress(servletRequest), request.email(),
                5, Duration.ofMinutes(15)
        );
        userRepository.findByEmail(request.email().trim().toLowerCase())
                .filter(user -> Boolean.TRUE.equals(user.getActive()))
                .filter(user -> !Boolean.TRUE.equals(user.getEmailVerified()))
                .ifPresent(user -> {
                    String token =
                            authTokenService.createEmailVerificationToken(user);
                    mailService.sendVerificationEmail(
                            user.getEmail(),
                            user.getFullName(),
                            token
                    );
                });
        return new MessageResponse(
                "Nếu tài khoản cần xác thực, email mới đã được gửi."
        );
    }

    @PostMapping("/forgot-password")
    public MessageResponse forgotPassword(
            @Valid @RequestBody EmailRequest request,
            HttpServletRequest servletRequest
    ) {
        if (!mailService.isConfigured()) {
            throw new ServiceUnavailableException(
                    "Dịch vụ email chưa được cấu hình. Vui lòng liên hệ quản trị viên"
            );
        }
        rateLimitService.check(
                "forgot", clientAddress(servletRequest), request.email(),
                5, Duration.ofMinutes(15)
        );
        userRepository.findByEmail(request.email().trim().toLowerCase())
                .filter(user -> Boolean.TRUE.equals(user.getActive()))
                .filter(user -> Boolean.TRUE.equals(user.getEmailVerified()))
                .ifPresent(user -> {
                    String otp = authTokenService.createPasswordResetOtp(user);
                    mailService.sendPasswordResetOtpEmail(
                            user.getEmail(),
                            user.getFullName(),
                            otp
                    );
                });
        return new MessageResponse(
                "Nếu email tồn tại, mã OTP đặt lại mật khẩu đã được gửi."
        );
    }

    @PostMapping("/reset-password")
    public MessageResponse resetPassword(
            @Valid @RequestBody ResetPasswordRequest request,
            HttpServletRequest servletRequest,
            HttpServletResponse servletResponse
    ) {
        rateLimitService.check(
                "reset", clientAddress(servletRequest), request.email(),
                5, Duration.ofMinutes(15)
        );
        User user = userRepository.findByEmail(
                        request.email().trim().toLowerCase()
                )
                .filter(User::getActive)
                .filter(candidate -> Boolean.TRUE.equals(candidate.getEmailVerified()))
                .orElseThrow(() -> new IllegalArgumentException(
                        "Email hoặc mã OTP không hợp lệ"
                ));
        authTokenService.resetPasswordWithOtp(
                user,
                request.otp(),
                request.newPassword()
        );
        cookieService.clearSession(servletResponse);
        return new MessageResponse(
                "Đặt lại mật khẩu thành công. Bạn có thể đăng nhập."
        );
    }

    private String clientAddress(HttpServletRequest request) {
        String forwarded = request.getHeader("X-Forwarded-For");
        if (forwarded != null && !forwarded.isBlank()) {
            return forwarded.split(",", 2)[0].trim();
        }
        return request.getRemoteAddr();
    }
}
