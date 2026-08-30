package com.fittrack.nutrition.dto;

import com.fittrack.nutrition.entity.NutritionDayStatus;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class NutritionDayStatusRequest {
    @NotNull
    private NutritionDayStatus status;
}
