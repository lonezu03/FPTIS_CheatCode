package com.fittrack.user.controller;

import com.fittrack.user.dto.AdminUserDtos.AdminUserResponse;
import com.fittrack.user.dto.AdminUserDtos.ResetPasswordRequest;
import com.fittrack.user.dto.AdminUserDtos.UpdateAdminUserRequest;
import com.fittrack.user.entity.User;
import com.fittrack.user.service.AdminUserService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import com.fittrack.common.dto.PageResponse;

@RestController
@RequestMapping("/api/admin/users")
@RequiredArgsConstructor
public class AdminUserController {

    private final AdminUserService adminUserService;

    @GetMapping
    public List<AdminUserResponse> getUsers(
            @RequestParam(required = false) String keyword
    ) {
        return adminUserService.getUsers(keyword);
    }

    @GetMapping("/page")
    public PageResponse<AdminUserResponse> getUsersPage(
            @RequestParam(required = false) String keyword,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size
    ) {
        return adminUserService.getUsersPage(keyword, page, size);
    }

    @PatchMapping("/{id}")
    public AdminUserResponse updateUser(
            Authentication authentication,
            @PathVariable String id,
            @Valid @RequestBody UpdateAdminUserRequest request
    ) {
        return adminUserService.updateUser(
                (User) authentication.getPrincipal(),
                id,
                request
        );
    }

    @PostMapping("/{id}/reset-password")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void resetPassword(
            Authentication authentication,
            @PathVariable String id,
            @Valid @RequestBody ResetPasswordRequest request
    ) {
        adminUserService.resetPassword((User) authentication.getPrincipal(), id, request);
    }
}
