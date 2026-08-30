package com.fittrack.nutrition.dto;

import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class NutritionTotalsResponse {
    private Double calories;
    private Double protein;
    private Double carbs;
    private Double fat;
}
