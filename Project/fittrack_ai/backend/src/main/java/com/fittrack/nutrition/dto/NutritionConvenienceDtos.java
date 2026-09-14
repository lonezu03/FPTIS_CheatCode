package com.fittrack.nutrition.dto;

import com.fittrack.nutrition.entity.NutritionCollectionType;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

public final class NutritionConvenienceDtos {
    private NutritionConvenienceDtos() {
    }

    public record FoodShortcutResponse(
            FoodResponse food,
            boolean favorite,
            int useCount,
            LocalDateTime lastUsedAt
    ) {
    }

    public record FavoriteFoodRequest(boolean favorite) {
    }

    public record CollectionItemRequest(
            @NotBlank String foodId,
            @NotNull @Positive Double servingAmount,
            @NotBlank String servingUnit
    ) {
    }

    public record CollectionRequest(
            @NotBlank @Size(max = 160) String name,
            @Size(max = 500) String description,
            @NotNull NutritionCollectionType type,
            @NotNull @Positive Double servings,
            @NotEmpty List<@Valid CollectionItemRequest> items
    ) {
    }

    public record CollectionItemResponse(
            String foodId,
            String foodName,
            Double servingAmount,
            String servingUnit,
            Double calories,
            Double protein,
            Double carbs,
            Double fat
    ) {
    }

    public record CollectionResponse(
            String id,
            String name,
            String description,
            NutritionCollectionType type,
            Double servings,
            Double caloriesPerServing,
            Double proteinPerServing,
            Double carbsPerServing,
            Double fatPerServing,
            List<CollectionItemResponse> items,
            LocalDateTime updatedAt
    ) {
    }

    public record ConvenienceResponse(
            List<FoodShortcutResponse> recentFoods,
            List<FoodShortcutResponse> favoriteFoods,
            List<CollectionResponse> savedMeals,
            List<CollectionResponse> recipes
    ) {
    }

    public record LogCollectionRequest(
            @NotNull LocalDate logDate,
            @NotBlank String mealType,
            @NotNull @Positive Double servings
    ) {
    }
}
