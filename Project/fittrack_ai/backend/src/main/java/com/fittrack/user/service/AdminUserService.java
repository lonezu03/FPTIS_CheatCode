package com.fittrack.user.service;

import com.fittrack.common.exception.ConflictException;
import com.fittrack.common.exception.ResourceNotFoundException;
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

@Service
@RequiredArgsConstructor
public class AdminUserService {

    private static final String ADMIN = "ADMIN";

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    @Transactional(readOnly = true)
    public List<AdminUserResponse> getUsers(String keyword) {
        String normalizedKeyword = keyword == null ? "" : keyword.trim();
        return userRepository.searchForAdmin(normalizedKeyword)
                .stream()
                .map(this::toResponse)
                .toList();
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
        return toResponse(userRepository.save(target));
    }

    @Transactional
    public void resetPassword(String userId, ResetPasswordRequest request) {
        User target = userRepository.findByIdForUpdate(userId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy tài khoản"));
        target.setPassword(passwordEncoder.encode(request.newPassword()));
        userRepository.save(target);
    }

    private AdminUserResponse toResponse(User user) {
        return new AdminUserResponse(
                user.getId(),
                user.getEmail(),
                user.getFullName(),
                user.getRole(),
                Boolean.TRUE.equals(user.getActive()),
                user.getCreatedAt()
        );
    }
}
