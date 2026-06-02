package com.fittrack.nutrition.dto;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class UpdateMealItemRequest {
    private String foodId;
    private Double quantity;
}

