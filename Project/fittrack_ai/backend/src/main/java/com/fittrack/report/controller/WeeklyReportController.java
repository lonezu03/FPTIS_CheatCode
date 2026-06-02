package com.fittrack.report.controller;

import com.fittrack.report.dto.WeeklyReportResponse;
import com.fittrack.report.service.WeeklyReportService;
import com.fittrack.user.entity.User;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;

@RestController
@RequestMapping("/api/reports")
@RequiredArgsConstructor
public class WeeklyReportController {

    private final WeeklyReportService weeklyReportService;

    @GetMapping("/weekly")
    public WeeklyReportResponse getWeeklyReport(
            Authentication authentication,
            @RequestParam(required = false) LocalDate fromDate,
            @RequestParam(required = false) LocalDate toDate
    ) {
        User user = (User) authentication.getPrincipal();

        return weeklyReportService.getWeeklyReport(user, fromDate, toDate);
    }
}

