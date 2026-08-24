package com.fittrack.notification.controller;

import com.fittrack.lunch.service.LunchNotificationService;
import com.fittrack.notification.dto.NotificationDtos.BroadcastRequest;
import com.fittrack.notification.dto.NotificationDtos.BroadcastResponse;
import com.fittrack.notification.dto.NotificationDtos.TestEmailResponse;
import com.fittrack.auth.service.ApplicationMailService;
import com.fittrack.common.exception.ExternalServiceException;
import com.fittrack.common.exception.ServiceUnavailableException;
import jakarta.validation.Valid;
import com.fittrack.audit.service.AuditService;
import com.fittrack.user.entity.User;
import org.springframework.security.core.Authentication;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/admin/notifications")
@RequiredArgsConstructor
public class AdminNotificationController {

    private final LunchNotificationService notificationService;
    private final AuditService auditService;
    private final ApplicationMailService mailService;

    @GetMapping("/mail-status")
    public ApplicationMailService.MailStatus mailStatus() {
        return mailService.status();
    }

    @PostMapping("/test-email")
    public TestEmailResponse testEmail(Authentication authentication) {
        User admin = (User) authentication.getPrincipal();
        if (!mailService.isConfigured()) {
            throw new ServiceUnavailableException(mailService.status().message());
        }
        if (!mailService.sendTestEmail(admin.getEmail(), admin.getFullName())) {
            throw new ExternalServiceException(
                    mailService.deliveryFailureMessage()
            );
        }
        return new TestEmailResponse(
                "Đã gửi email thử tới tài khoản admin",
                admin.getEmail()
        );
    }

    @PostMapping("/broadcast")
    public BroadcastResponse broadcast(
            Authentication authentication,
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
        auditService.record(
                (User) authentication.getPrincipal(),
                "NOTIFICATION_BROADCAST",
                "NOTIFICATION",
                null,
                Map.of("recipientCount", count, "sendToAll", request.sendToAll())
        );
        return new BroadcastResponse(
                "Đã gửi thông báo",
                count
        );
    }
}
