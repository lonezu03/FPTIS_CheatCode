package com.fittrack.nutrition.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.PositiveOrZero;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class CreateFoodRequest {
    @NotBlank
    @Size(max = 255)
    private String name;
    @PositiveOrZero
    private Double calories;
    @PositiveOrZero
    private Double protein;
    @PositiveOrZero
    private Double carbs;
    @PositiveOrZero
    private Double fat;
    @PositiveOrZero
    private Double fiber;
    @PositiveOrZero
    private Double sugar;
    @PositiveOrZero
    private Double sodium;
    @PositiveOrZero
    private Double potassium;
    @PositiveOrZero
    private Double calcium;
    @PositiveOrZero
    private Double iron;
    @PositiveOrZero
    private Double vitaminC;
    @PositiveOrZero
    private Double water;
    @Size(max = 100)
    private String unit;
    @Positive
    private Double servingSizeGrams;
    @Size(max = 30)
    private String dataSourceType;
    @Size(max = 255)
    private String dataSourceName;
    private Boolean verified;
    @Size(max = 2_000_000)
    private String imageUrl;
}

