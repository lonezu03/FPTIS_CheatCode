package com.fittrack.nutrition.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class CreateMealItemRequest {
    @NotBlank
    private String foodId;

    @NotNull
    @Positive
    private Double quantity;
}

