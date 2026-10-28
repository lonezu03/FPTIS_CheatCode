package com.fittrack.nutrition.planning;

import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import java.time.LocalDate;
import java.util.List;

public final class PlanningDtos {
    private PlanningDtos() {}
    public record ItemRequest(@NotBlank String foodId, @NotNull @DecimalMin("0.001") @DecimalMax("100000") Double servingAmount,
                              @NotBlank @Pattern(regexp="SERVING|GRAM|ML") String servingUnit) {}
    public record MealRequest(Long version, @NotNull LocalDate date,
            @NotBlank @Pattern(regexp="BREAKFAST|LUNCH|DINNER|SNACK") String mealType,
            @NotBlank @Size(max=160) String name, @Size(max=1000) String notes,
            String collectionId, @DecimalMin("0.001") @DecimalMax("1000") Double servings,
            @Size(max=100) List<@Valid ItemRequest> items) {}
    public record ItemSnapshot(String foodId, String foodName, String foodUnit, Double servingSize,
            Double servingAmount, String servingUnit, Double calories, Double protein, Double carbs, Double fat,
            Double fiber, Double sugar, Double sodium, Double potassium, Double calcium, Double iron,
            Double vitaminC, Double water, String sourceType, String sourceName, Boolean verified) {}
    public record Totals(double calories, double protein, double carbs, double fat, int knownMicronutrientValues, int possibleMicronutrientValues) {}
    public record WeekSummary(LocalDate week, int plannedMealCount, Totals totals) {}
    public record MealResponse(String id, long version, LocalDate date, String mealType, String name, String notes,
                               List<ItemSnapshot> items, Totals totals, String loggedMealId) {}
    public record VersionRequest(@NotNull @PositiveOrZero Long version) {}
    public record CopyWeekRequest(@NotNull LocalDate fromWeek, @NotNull LocalDate toWeek,
                                   @NotBlank @Size(max=80) String operationId) {}
    public record LogResult(String mealLogId, boolean alreadyLogged) {}
    public record GroceryResponse(long version, LocalDate week, List<GroceryItemResponse> items) {}
    public record GroceryItemResponse(String id, String foodId, String name, Double amount, String unit,
                                      boolean checked, boolean manual, boolean stale) {}
    public record GroceryRefreshRequest(@NotNull LocalDate week, @NotNull @PositiveOrZero Long version) {}
    public record GroceryManualRequest(@NotNull LocalDate week, @NotNull @PositiveOrZero Long version,
            @NotBlank @Size(max=160) String name, @NotNull @DecimalMin("0.001") @DecimalMax("1000000") Double amount,
            @NotBlank @Size(max=30) String unit) {}
    public record GroceryCheckRequest(@NotNull LocalDate week, @NotNull @PositiveOrZero Long version, boolean checked) {}
    // Only meal templates are shared. Actual diary IDs, source owners and personal notes never leave the owner.
    public record TemplateMeal(int dayOffset, String mealType, String name, List<ItemRequest> items) {}
}
