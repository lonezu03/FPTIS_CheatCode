package com.fittrack.auth.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public final class AuthFlowDtos {

    private AuthFlowDtos() {
    }

    public record RegistrationResponse(
            String email,
            String message,
            boolean verificationRequired,
            boolean emailSent
    ) {
    }

    public record MessageResponse(String message) {
    }

    public record EmailRequest(
            @Email(message = "Email không hợp lệ")
            @NotBlank(message = "Vui lòng nhập email")
            String email
    ) {
    }

    public record TokenRequest(
            @NotBlank(message = "Mã xác thực không hợp lệ")
            String token
    ) {
    }

    public record ResetPasswordRequest(
            @NotBlank(message = "Mã đặt lại mật khẩu không hợp lệ")
            String token,
            @NotBlank(message = "Vui lòng nhập mật khẩu mới")
            @Size(
                    min = 8,
                    max = 72,
                    message = "Mật khẩu phải từ 8 đến 72 ký tự"
            )
            String newPassword
    ) {
    }
}
