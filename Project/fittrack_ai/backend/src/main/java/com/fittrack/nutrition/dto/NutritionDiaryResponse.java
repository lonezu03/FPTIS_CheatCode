package com.fittrack.nutrition.dto;

import com.fittrack.nutrition.entity.NutritionDayStatus;
import lombok.Builder;
import lombok.Getter;

import java.time.LocalDate;
import java.util.List;

@Getter
@Builder
public class NutritionDiaryResponse {
    private LocalDate date;
    private NutritionDayStatus status;
    private Boolean statusExplicit;
    private NutritionTotalsResponse consumed;
    private NutritionTotalsResponse targets;
    private NutritionTotalsResponse remaining;
    private Integer waterMl;
    private Integer waterTargetMl;
    private List<MealLogResponse> meals;
}
