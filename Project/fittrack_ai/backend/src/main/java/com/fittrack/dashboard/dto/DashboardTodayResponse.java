package com.fittrack.dashboard.dto;

import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class DashboardTodayResponse {
    private Double totalCalories;
    private Double totalProtein;
    private Double totalCarbs;
    private Double totalFat;

    private Double targetCalories;
    private Double targetProtein;
    private Double targetCarbs;
    private Double targetFat;

    private Double caloriesProgressPercent;
    private Double proteinProgressPercent;
    private Double carbsProgressPercent;
    private Double fatProgressPercent;

    private Integer mealCount;
    private Integer workoutCount;
    private String latestWorkoutNote;
}

