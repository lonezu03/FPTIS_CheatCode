package com.fittrack.notification.controller;

import com.fittrack.lunch.service.LunchNotificationService;
import com.fittrack.notification.dto.NotificationDtos.BroadcastRequest;
import com.fittrack.notification.dto.NotificationDtos.BroadcastResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/admin/notifications")
@RequiredArgsConstructor
public class AdminNotificationController {

    private final LunchNotificationService notificationService;

    @PostMapping("/broadcast")
    public BroadcastResponse broadcast(
            @Valid @RequestBody BroadcastRequest request
    ) {
        int count = notificationService.broadcast(
                request.title().trim(),
                request.message().trim(),
                request.sendToAll(),
                request.recipientUserIds() == null
                        ? List.of()
                        : request.recipientUserIds()
        );
        return new BroadcastResponse(
                "Đã gửi thông báo",
                count
        );
    }
}
