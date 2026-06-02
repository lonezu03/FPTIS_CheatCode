package com.fittrack.nutrition.dto;

import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class MealItemResponse {
    private String id;
    private String foodId;
    private String foodName;
    private Double quantity;
    private Double calories;
    private Double protein;
    private Double carbs;
    private Double fat;
}

