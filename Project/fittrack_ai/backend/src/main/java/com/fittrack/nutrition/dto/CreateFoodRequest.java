package com.fittrack.nutrition.dto;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class CreateFoodRequest {
    private String name;
    private Double calories;
    private Double protein;
    private Double carbs;
    private Double fat;
    private String unit;
}

