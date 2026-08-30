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
    private Double servingAmount;
    private String servingUnit;
    private Double gramsEquivalent;
    private Double calories;
    private Double protein;
    private Double carbs;
    private Double fat;
    private Double fiber;
    private Double sugar;
    private Double sodium;
    private Double potassium;
    private Double calcium;
    private Double iron;
    private Double vitaminC;
    private Double water;
}

