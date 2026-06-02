package com.fittrack.dashboard.controller;

import com.fittrack.dashboard.dto.DashboardProgressResponse;
import com.fittrack.dashboard.dto.DashboardTodayResponse;
import com.fittrack.dashboard.service.DashboardService;
import com.fittrack.user.entity.User;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/dashboard")
@RequiredArgsConstructor
public class DashboardController {

    private final DashboardService dashboardService;

    @GetMapping("/today")
    public DashboardTodayResponse getTodayDashboard(Authentication authentication) {
        User user = (User) authentication.getPrincipal();

        return dashboardService.getTodayDashboard(user);
    }

    @GetMapping("/progress")
    public DashboardProgressResponse getProgress(Authentication authentication) {
        User user = (User) authentication.getPrincipal();

        return dashboardService.getProgress(user);
    }
}

