package com.fittrack.user.service;

import com.fittrack.common.exception.ConflictException;
import com.fittrack.common.exception.ResourceNotFoundException;
import com.fittrack.auth.service.AuthTokenService;
import com.fittrack.audit.service.AuditService;
import com.fittrack.user.dto.AdminUserDtos.AdminUserResponse;
import com.fittrack.user.dto.AdminUserDtos.ResetPasswordRequest;
import com.fittrack.user.dto.AdminUserDtos.UpdateAdminUserRequest;
import com.fittrack.user.entity.User;
import com.fittrack.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Locale;
import java.util.Objects;
import java.util.Map;
import org.springframework.data.domain.PageRequest;
import com.fittrack.common.dto.PageResponse;

@Service
@RequiredArgsConstructor
public class AdminUserService {

    private static final String ADMIN = "ADMIN";

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final AuthTokenService authTokenService;
    private final AuditService auditService;

    @Transactional(readOnly = true)
    public List<AdminUserResponse> getUsers(String keyword) {
        String normalizedKeyword = keyword == null ? "" : keyword.trim();
        return userRepository.searchForAdmin(normalizedKeyword)
                .stream()
                .map(this::toResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public PageResponse<AdminUserResponse> getUsersPage(
            String keyword,
            int page,
            int size
    ) {
        String normalizedKeyword = keyword == null ? "" : keyword.trim();
        var result = userRepository.searchForAdminPage(
                normalizedKeyword,
                PageRequest.of(Math.max(page, 0), Math.min(Math.max(size, 1), 100))
        ).map(this::toResponse);
        return PageResponse.from(result);
    }

    @Transactional
    public AdminUserResponse updateUser(
            User currentAdmin,
            String userId,
            UpdateAdminUserRequest request
    ) {
        User target = userRepository.findByIdForUpdate(userId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy tài khoản"));

        String nextRole = request.role() == null
                ? target.getRole()
                : request.role().trim().toUpperCase(Locale.ROOT);
        boolean nextActive = request.active() == null
                ? Boolean.TRUE.equals(target.getActive())
                : request.active();

        if (Objects.equals(currentAdmin.getId(), target.getId())
                && (!ADMIN.equals(nextRole) || !nextActive)) {
            throw new ConflictException(
                    "Bạn không thể tự thu hồi quyền admin hoặc khóa tài khoản đang đăng nhập"
            );
        }

        boolean removesActiveAdmin = ADMIN.equalsIgnoreCase(target.getRole())
                && Boolean.TRUE.equals(target.getActive())
                && (!ADMIN.equals(nextRole) || !nextActive);
        if (removesActiveAdmin
                && userRepository.countByRoleIgnoreCaseAndActiveTrue(ADMIN) <= 1) {
            throw new ConflictException("Hệ thống phải còn ít nhất một admin đang hoạt động");
        }

        if (request.fullName() != null) {
            target.setFullName(request.fullName().trim());
        }
        target.setRole(nextRole);
        target.setActive(nextActive);
        if (request.lunchEnabled() != null) {
            target.setLunchEnabled(request.lunchEnabled());
        }
        if (request.fitnessEnabled() != null) {
            target.setFitnessEnabled(request.fitnessEnabled());
        }
        if (request.healthEnabled() != null) {
            target.setHealthEnabled(request.healthEnabled());
        }
        if (request.chatbotEnabled() != null) {
            target.setChatbotEnabled(request.chatbotEnabled());
        }
        if (request.todoEnabled() != null) {
            target.setTodoEnabled(request.todoEnabled());
        }
        if (request.scheduleEnabled() != null) {
            target.setScheduleEnabled(request.scheduleEnabled());
        }
        AdminUserResponse response = toResponse(userRepository.save(target));
        auditService.record(currentAdmin, "USER_UPDATED", "USER", target.getId(), Map.of(
                "role", target.getRole(),
                "active", Boolean.TRUE.equals(target.getActive()),
                "lunchEnabled", Boolean.TRUE.equals(target.getLunchEnabled()),
                "fitnessEnabled", Boolean.TRUE.equals(target.getFitnessEnabled()),
                "healthEnabled", Boolean.TRUE.equals(target.getHealthEnabled()),
                "chatbotEnabled", Boolean.TRUE.equals(target.getChatbotEnabled()),
                "todoEnabled", Boolean.TRUE.equals(target.getTodoEnabled()),
                "scheduleEnabled", Boolean.TRUE.equals(target.getScheduleEnabled())
        ));
        return response;
    }

    @Transactional
    public void resetPassword(User currentAdmin, String userId, ResetPasswordRequest request) {
        User target = userRepository.findByIdForUpdate(userId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy tài khoản"));
        target.setPassword(passwordEncoder.encode(request.newPassword()));
        target.setPasswordChangeRequired(true);
        authTokenService.revokeAllSessions(target);
        userRepository.save(target);
        auditService.record(currentAdmin, "USER_PASSWORD_RESET", "USER", target.getId(), Map.of(
                "forceChange", true
        ));
    }

    private AdminUserResponse toResponse(User user) {
        return new AdminUserResponse(
                user.getId(),
                user.getEmail(),
                user.getFullName(),
                user.getRole(),
                Boolean.TRUE.equals(user.getActive()),
                Boolean.TRUE.equals(user.getEmailVerified()),
                Boolean.TRUE.equals(user.getLunchEnabled()),
                Boolean.TRUE.equals(user.getFitnessEnabled()),
                Boolean.TRUE.equals(user.getHealthEnabled()),
                Boolean.TRUE.equals(user.getChatbotEnabled()),
                Boolean.TRUE.equals(user.getTodoEnabled()),
                Boolean.TRUE.equals(user.getScheduleEnabled()),
                user.getCreatedAt()
        );
    }
}
