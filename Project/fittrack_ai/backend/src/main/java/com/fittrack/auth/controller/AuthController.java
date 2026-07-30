package com.fittrack.auth.controller;

import com.fittrack.auth.dto.AuthResponse;
import com.fittrack.auth.dto.AuthFlowDtos.*;
import com.fittrack.auth.dto.LoginRequest;
import com.fittrack.auth.dto.RegisterRequest;
import com.fittrack.auth.service.AuthService;
import com.fittrack.auth.service.AuthTokenService;
import com.fittrack.auth.service.ApplicationMailService;
import com.fittrack.user.entity.User;
import com.fittrack.user.repository.UserRepository;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;
    private final AuthTokenService authTokenService;
    private final ApplicationMailService mailService;
    private final UserRepository userRepository;

    @PostMapping("/register")
    public RegistrationResponse register(
            @Valid @RequestBody RegisterRequest request
    ) {
        return authService.register(request);
    }

    @PostMapping("/login")
    public AuthResponse login(@Valid @RequestBody LoginRequest request) {
        return authService.login(request);
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
            @Valid @RequestBody EmailRequest request
    ) {
        userRepository.findByEmail(request.email().trim().toLowerCase())
                .filter(User::getActive)
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
            @Valid @RequestBody EmailRequest request
    ) {
        userRepository.findByEmail(request.email().trim().toLowerCase())
                .filter(User::getActive)
                .filter(user -> Boolean.TRUE.equals(user.getEmailVerified()))
                .ifPresent(user -> {
                    String token = authTokenService.createPasswordResetToken(user);
                    mailService.sendPasswordResetEmail(
                            user.getEmail(),
                            user.getFullName(),
                            token
                    );
                });
        return new MessageResponse(
                "Nếu email tồn tại, hướng dẫn đặt lại mật khẩu đã được gửi."
        );
    }

    @PostMapping("/reset-password")
    public MessageResponse resetPassword(
            @Valid @RequestBody ResetPasswordRequest request
    ) {
        authTokenService.resetPassword(
                request.token(),
                request.newPassword()
        );
        return new MessageResponse(
                "Đặt lại mật khẩu thành công. Bạn có thể đăng nhập."
        );
    }
}
