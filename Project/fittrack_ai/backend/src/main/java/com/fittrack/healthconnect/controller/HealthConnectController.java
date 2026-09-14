package com.fittrack.healthconnect.controller;

import com.fittrack.healthconnect.dto.HealthConnectDtos.*;
import com.fittrack.healthconnect.service.HealthConnectService;
import com.fittrack.user.entity.User;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;

@RestController
@RequestMapping("/api/health-connect")
@RequiredArgsConstructor
public class HealthConnectController {
    private final HealthConnectService service;

    @PostMapping("/sync")
    public SyncBatchResponse sync(
            Authentication authentication,
            @Valid @RequestBody SyncBatchRequest request
    ) {
        return service.sync((User) authentication.getPrincipal(), request);
    }

    @GetMapping("/day")
    public DailyHealthConnectResponse day(
            Authentication authentication,
            @RequestParam(required = false) LocalDate date
    ) {
        return service.day((User) authentication.getPrincipal(), date);
    }
}
