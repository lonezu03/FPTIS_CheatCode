package com.fittrack.nutrition.dto;

import lombok.Builder;
import lombok.Getter;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

@Getter
@Builder
public class MealLogResponse {
    private String id;
    private String mealType;
    private LocalDate logDate;
    private Double totalCalories;
    private Double totalProtein;
    private Double totalCarbs;
    private Double totalFat;
    private Double totalFiber;
    private Double totalSugar;
    private Double totalSodium;
    private Double totalPotassium;
    private Double totalCalcium;
    private Double totalIron;
    private Double totalVitaminC;
    private Double totalWater;
    private LocalDateTime createdAt;
    private String sourceType;
    private String sourceId;
    private Boolean readOnly;
    private List<MealItemResponse> items;
}

