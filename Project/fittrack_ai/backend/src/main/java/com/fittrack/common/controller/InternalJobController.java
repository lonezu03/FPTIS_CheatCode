package com.fittrack.common.controller;

import com.fittrack.health.service.HealthReminderService;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.Map;

@RestController
@RequestMapping("/api/internal/jobs")
public class InternalJobController {

    private final HealthReminderService reminderService;
    private final String jobSecret;

    public InternalJobController(
            HealthReminderService reminderService,
            @Value("${app.scheduler.job-secret:}") String jobSecret
    ) {
        this.reminderService = reminderService;
        this.jobSecret = jobSecret;
    }

    @PostMapping("/reminders")
    public Map<String, Object> dispatchReminders(
            @RequestHeader(value = "X-Job-Secret", required = false) String suppliedSecret
    ) {
        if (!matches(suppliedSecret)) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Invalid job secret");
        }
        int dispatched = reminderService.dispatchDueRemindersNow();
        return Map.of("status", "OK", "dispatched", dispatched);
    }

    private boolean matches(String suppliedSecret) {
        if (jobSecret == null || jobSecret.length() < 32 || suppliedSecret == null) {
            return false;
        }
        return MessageDigest.isEqual(
                jobSecret.getBytes(StandardCharsets.UTF_8),
                suppliedSecret.getBytes(StandardCharsets.UTF_8)
        );
    }
}
