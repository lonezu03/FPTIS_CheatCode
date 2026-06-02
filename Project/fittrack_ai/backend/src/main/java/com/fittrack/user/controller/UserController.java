package com.fittrack.user.controller;

import com.fittrack.user.dto.UpdateUserProfileRequest;
import com.fittrack.user.dto.UserProfileResponse;
import com.fittrack.user.entity.User;
import com.fittrack.user.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;

    @GetMapping("/me")
    public UserProfileResponse me(Authentication authentication) {
        User user = (User) authentication.getPrincipal();

        return userService.getProfile(user);
    }

    @PutMapping("/me")
    public UserProfileResponse updateMe(
            Authentication authentication,
            @RequestBody UpdateUserProfileRequest request
    ) {
        User user = (User) authentication.getPrincipal();

        return userService.updateProfile(user, request);
    }
}