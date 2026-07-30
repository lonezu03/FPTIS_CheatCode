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
    private Double fiber;
    private Double sugar;
    private Double sodium;
    private Double potassium;
    private Double calcium;
    private Double iron;
    private Double vitaminC;
    private Double water;
    private String unit;
    private String imageUrl;
    private Boolean custom;
    private Boolean active;
    private String approvalStatus;
    private String submittedById;
    private String submittedByName;
    private String adminNote;
}

