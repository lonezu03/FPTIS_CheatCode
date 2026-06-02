package com.fittrack.nutrition.dto;

import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class FoodResponse {
    private String id;
    private String name;
    private Double calories;
    private Double protein;
    private Double carbs;
    private Double fat;
    private String unit;
    private Boolean custom;
    private Boolean active;
}

