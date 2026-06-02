package com.fittrack.nutrition.dto;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class CreateMealItemRequest {
    private String foodId;
    private Double quantity;
}

