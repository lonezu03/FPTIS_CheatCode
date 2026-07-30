package com.fittrack.health.controller;

import com.fittrack.health.dto.HealthDtos.ReminderRequest;
import com.fittrack.health.dto.HealthDtos.ReminderResponse;
import com.fittrack.health.service.HealthReminderService;
import com.fittrack.user.entity.User;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/reminders")
@RequiredArgsConstructor
public class HealthReminderController {

    private final HealthReminderService reminderService;

    @GetMapping
    public List<ReminderResponse> getMine(
            @AuthenticationPrincipal User user
    ) {
        return reminderService.getMine(user);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public ReminderResponse create(
            @AuthenticationPrincipal User user,
            @Valid @RequestBody ReminderRequest request
    ) {
        return reminderService.create(user, request);
    }

    @PutMapping("/{id}")
    public ReminderResponse update(
            @AuthenticationPrincipal User user,
            @PathVariable String id,
            @Valid @RequestBody ReminderRequest request
    ) {
        return reminderService.update(user, id, request);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(
            @AuthenticationPrincipal User user,
            @PathVariable String id
    ) {
        reminderService.delete(user, id);
    }
}
