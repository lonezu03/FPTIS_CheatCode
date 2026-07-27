package com.fittrack.nutrition.dto;

import jakarta.validation.constraints.NotBlank;
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
    @Size(max = 100)
    private String unit;
    @Size(max = 2_000_000)
    private String imageUrl;
}

