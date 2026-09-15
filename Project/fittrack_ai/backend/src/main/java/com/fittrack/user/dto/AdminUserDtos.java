package com.fittrack.user.dto;

import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

import java.time.LocalDateTime;

public final class AdminUserDtos {

    private AdminUserDtos() {
    }

    public record AdminUserResponse(
            String id,
            String email,
            String fullName,
            String role,
            boolean active,
            boolean emailVerified,
            boolean lunchEnabled,
            boolean fitnessEnabled,
            boolean healthEnabled,
            boolean chatbotEnabled,
            boolean todoEnabled,
            boolean scheduleEnabled,
            boolean quoteEnabled,
            boolean financeEnabled,
            LocalDateTime createdAt
    ) {
    }

    public record UpdateAdminUserRequest(
            @Size(max = 255) String fullName,
            @Pattern(regexp = "USER|ADMIN", message = "role chỉ nhận USER hoặc ADMIN")
            String role,
            Boolean active,
            Boolean lunchEnabled,
            Boolean fitnessEnabled,
            Boolean healthEnabled,
            Boolean chatbotEnabled,
            Boolean todoEnabled,
            Boolean scheduleEnabled,
            Boolean quoteEnabled,
            Boolean financeEnabled
    ) {
        public UpdateAdminUserRequest(String fullName, String role, Boolean active) {
            this(fullName, role, active, null, null, null, null, null, null, null, null);
        }

        public UpdateAdminUserRequest(
                String fullName,
                String role,
                Boolean active,
                Boolean lunchEnabled,
                Boolean fitnessEnabled,
                Boolean healthEnabled,
                Boolean chatbotEnabled,
                Boolean todoEnabled,
                Boolean scheduleEnabled,
                Boolean quoteEnabled
        ) {
            this(fullName, role, active, lunchEnabled, fitnessEnabled, healthEnabled,
                    chatbotEnabled, todoEnabled, scheduleEnabled, quoteEnabled, null);
        }
    }

    public record ResetPasswordRequest(
            @NotBlank(message = "Vui lòng nhập mật khẩu mới")
            @Size(min = 8, max = 72, message = "Mật khẩu phải từ 8 đến 72 ký tự")
            String newPassword
    ) {
    }
}
