package com.fittrack.report.dto;

import lombok.Builder;
import lombok.Getter;

import java.time.LocalDate;
import java.util.List;

@Getter
@Builder
public class WeeklyReportResponse {
    private LocalDate fromDate;
    private LocalDate toDate;

    private Double averageCalories;
    private Double averageProtein;
    private Double averageCarbs;
    private Double averageFat;

    private Double targetCalories;
    private Double targetProtein;
    private Double targetCarbs;
    private Double targetFat;

    private Integer totalMeals;
    private Integer totalWorkouts;
    private Integer workoutDays;

    private Double startWeight;
    private Double endWeight;
    private Double weightChange;

    private Double startWaist;
    private Double endWaist;
    private Double waistChange;

    private Double caloriesCompliancePercent;
    private Double proteinCompliancePercent;

    private List<String> insights;

    private List<DailyNutritionSummaryResponse> dailyNutrition;
}

