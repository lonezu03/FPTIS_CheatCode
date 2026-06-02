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
    private LocalDateTime createdAt;
    private List<MealItemResponse> items;
}

