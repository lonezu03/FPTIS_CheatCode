package com.fittrack.notification.controller;

import com.fittrack.lunch.dto.LunchDtos.NotificationListResponse;
import com.fittrack.lunch.service.LunchNotificationService;
import com.fittrack.user.entity.User;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/notifications")
@RequiredArgsConstructor
public class NotificationController {

    private final LunchNotificationService notificationService;

    @GetMapping
    public NotificationListResponse getMine(
            @AuthenticationPrincipal User user
    ) {
        return notificationService.getMine(user);
    }

    @PatchMapping("/{id}/read")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void markRead(
            @AuthenticationPrincipal User user,
            @PathVariable String id
    ) {
        notificationService.markRead(user, id);
    }

    @PostMapping("/read-all")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void markAllRead(@AuthenticationPrincipal User user) {
        notificationService.markAllRead(user);
    }
}
