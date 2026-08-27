package com.fittrack.notification.controller;

import com.fittrack.notification.dto.NotificationPlaybookDtos.PlaybookRequest;
import com.fittrack.notification.dto.NotificationPlaybookDtos.PlaybookResponse;
import com.fittrack.notification.service.NotificationPlaybookService;
import com.fittrack.user.entity.User;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/admin/notification-playbooks")
@RequiredArgsConstructor
public class AdminNotificationPlaybookController {
    private final NotificationPlaybookService service;

    @GetMapping
    public List<PlaybookResponse> getAll() {
        return service.getAll();
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public PlaybookResponse create(
            Authentication authentication,
            @Valid @RequestBody PlaybookRequest request
    ) {
        return service.create((User) authentication.getPrincipal(), request);
    }

    @PatchMapping("/{id}")
    public PlaybookResponse update(
            @PathVariable String id,
            @Valid @RequestBody PlaybookRequest request
    ) {
        return service.update(id, request);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable String id) {
        service.delete(id);
    }
}
