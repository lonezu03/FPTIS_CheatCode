package com.fittrack.recommendation.dto;

import java.time.LocalDate;
import java.time.LocalDateTime;

public final class WeeklyCoachDtos {
    private WeeklyCoachDtos() {
    }

    public record WeeklyCheckInResponse(
            String id,
            LocalDate weekStart,
            LocalDate weekEnd,
            String status,
            boolean dataSufficient,
            double confidencePercent,
            int completeDays,
            int workoutDays,
            Double weightChange,
            double currentCalories,
            double proposedCalories,
            double currentProtein,
            double proposedProtein,
            String rationale,
            boolean canApply,
            LocalDateTime decidedAt
    ) {
    }

    public record CheckInDecisionRequest(String decision) {
    }
}
