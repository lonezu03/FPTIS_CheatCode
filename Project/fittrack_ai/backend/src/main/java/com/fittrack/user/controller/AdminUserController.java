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
            @PathVariable String id,
            @Valid @RequestBody ResetPasswordRequest request
    ) {
        adminUserService.resetPassword(id, request);
    }
}
