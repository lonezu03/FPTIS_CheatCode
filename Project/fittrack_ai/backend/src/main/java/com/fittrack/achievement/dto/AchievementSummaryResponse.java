package com.fittrack.achievement.dto;

import lombok.Builder;
import lombok.Getter;

import java.util.List;

@Getter
@Builder
public class AchievementSummaryResponse {
    private Integer mealLoggingStreak;
    private Integer workoutStreak;
    private Integer proteinHitDaysThisWeek;
    private Integer bodyTrackingDaysThisWeek;
    private List<AchievementResponse> achievements;
}

