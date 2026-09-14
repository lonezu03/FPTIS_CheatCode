package com.fittrack.nutrition.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

import java.util.List;

public final class FoodPhotoAnalysisDtos {
    private FoodPhotoAnalysisDtos() {}

    public record FoodPhotoAnalysisRequest(@NotBlank @Size(max = 2_000_000) String imageData) {}

    public record EstimatedFoodItem(String name, Double estimatedGrams, Double calories,
                                    Double protein, Double carbs, Double fat) {}

    public record FoodPhotoAnalysisResponse(List<EstimatedFoodItem> items, String note,
                                            boolean requiresConfirmation) {}
}
