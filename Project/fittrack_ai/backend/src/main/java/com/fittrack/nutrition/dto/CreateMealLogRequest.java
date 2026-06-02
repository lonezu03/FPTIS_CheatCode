package com.fittrack.nutrition.dto;

import lombok.Getter;
import lombok.Setter;

import java.time.LocalDate;
import java.util.List;

@Getter
@Setter
public class CreateMealLogRequest {
    private String mealType;
    private LocalDate logDate;
    private List<CreateMealItemRequest> items;
}

