package com.fittrack.health.controller;

import com.fittrack.health.dto.HealthDtos.HealthSummaryResponse;
import com.fittrack.health.service.HealthSummaryService;
import com.fittrack.user.entity.User;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/health-management")
@RequiredArgsConstructor
public class HealthSummaryController {

    private final HealthSummaryService healthSummaryService;

    @GetMapping("/summary")
    public HealthSummaryResponse summary(
            @AuthenticationPrincipal User user,
            @RequestParam(defaultValue = "30") int days
    ) {
        return healthSummaryService.summarize(user, days);
    }
}
