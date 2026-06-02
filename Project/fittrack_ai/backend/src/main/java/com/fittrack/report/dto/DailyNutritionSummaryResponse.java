package com.fittrack.report.dto;

import lombok.Builder;
import lombok.Getter;

import java.time.LocalDate;

@Getter
@Builder
public class DailyNutritionSummaryResponse {
    private LocalDate date;

    private Double calories;
    private Double protein;
    private Double carbs;
    private Double fat;

    private Double targetCalories;
    private Double targetProtein;

    private Double caloriesCompliancePercent;
    private Double proteinCompliancePercent;
}

