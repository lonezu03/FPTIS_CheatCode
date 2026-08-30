package com.fittrack.nutrition.mapper;

import com.fittrack.nutrition.dto.FoodResponse;
import com.fittrack.nutrition.dto.MealItemResponse;
import com.fittrack.nutrition.dto.MealLogResponse;
import com.fittrack.nutrition.entity.Food;
import com.fittrack.nutrition.entity.MealItem;
import com.fittrack.nutrition.entity.MealLog;
import com.fittrack.common.media.ImageReferences;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
public class NutritionMapper {

    public FoodResponse toFoodResponse(Food food) {
        return FoodResponse.builder()
                .id(food.getId())
                .name(food.getName())
                .calories(food.getCalories())
                .protein(food.getProtein())
                .carbs(food.getCarbs())
                .fat(food.getFat())
                .fiber(food.getFiber())
                .sugar(food.getSugar())
                .sodium(food.getSodium())
                .potassium(food.getPotassium())
                .calcium(food.getCalcium())
                .iron(food.getIron())
                .vitaminC(food.getVitaminC())
                .water(food.getWater())
                .unit(food.getUnit())
                .servingSizeGrams(food.getServingSizeGrams())
                .dataSourceType(food.getDataSourceType())
                .dataSourceName(food.getDataSourceName())
                .verified(food.getVerified())
                .imageUrl(ImageReferences.responseUrl(
                        food.getImageUrl(),
                        ImageReferences.foodPath(food.getId())
                ))
                .custom(food.getCustom())
                .active(food.getActive())
                .approvalStatus(food.getApprovalStatus())
                .submittedById(
                        food.getSubmittedBy() == null
                                ? null
                                : food.getSubmittedBy().getId()
                )
                .submittedByName(
                        food.getSubmittedBy() == null
                                ? null
                                : food.getSubmittedBy().getFullName()
                )
                .adminNote(food.getAdminNote())
                .build();
    }

    public List<FoodResponse> toFoodResponseList(List<Food> foods) {
        return foods.stream()
                .map(this::toFoodResponse)
                .toList();
    }

    public MealItemResponse toMealItemResponse(MealItem item) {
        Food food = item.getFood();

        return MealItemResponse.builder()
                .id(item.getId())
                .foodId(food.getId())
                .foodName(food.getName())
                .quantity(item.getQuantity())
                .servingAmount(item.getServingAmount())
                .servingUnit(item.getServingUnit())
                .gramsEquivalent(item.getGramsEquivalent())
                .calories(item.getCalories())
                .protein(item.getProtein())
                .carbs(item.getCarbs())
                .fat(item.getFat())
                .fiber(item.getFiber())
                .sugar(item.getSugar())
                .sodium(item.getSodium())
                .potassium(item.getPotassium())
                .calcium(item.getCalcium())
                .iron(item.getIron())
                .vitaminC(item.getVitaminC())
                .water(item.getWater())
                .build();
    }

    public MealLogResponse toMealLogResponse(MealLog mealLog) {
        return MealLogResponse.builder()
                .id(mealLog.getId())
                .mealType(mealLog.getMealType())
                .logDate(mealLog.getLogDate())
                .totalCalories(mealLog.getTotalCalories())
                .totalProtein(mealLog.getTotalProtein())
                .totalCarbs(mealLog.getTotalCarbs())
                .totalFat(mealLog.getTotalFat())
                .totalFiber(sum(mealLog, MealItem::getFiber))
                .totalSugar(sum(mealLog, MealItem::getSugar))
                .totalSodium(sum(mealLog, MealItem::getSodium))
                .totalPotassium(sum(mealLog, MealItem::getPotassium))
                .totalCalcium(sum(mealLog, MealItem::getCalcium))
                .totalIron(sum(mealLog, MealItem::getIron))
                .totalVitaminC(sum(mealLog, MealItem::getVitaminC))
                .totalWater(sum(mealLog, MealItem::getWater))
                .createdAt(mealLog.getCreatedAt())
                .sourceType(mealLog.getSourceLunchOrderId() == null ? "MANUAL" : "LUNCH_ORDER")
                .sourceId(mealLog.getSourceLunchOrderId())
                .readOnly(mealLog.getSourceLunchOrderId() != null)
                .items(mealLog.getItems().stream()
                        .map(this::toMealItemResponse)
                        .toList())
                .build();
    }

    private double sum(
            MealLog mealLog,
            java.util.function.Function<MealItem, Double> getter
    ) {
        return mealLog.getItems()
                .stream()
                .map(getter)
                .filter(java.util.Objects::nonNull)
                .mapToDouble(Double::doubleValue)
                .sum();
    }

    public List<MealLogResponse> toMealLogResponseList(List<MealLog> mealLogs) {
        return mealLogs.stream()
                .map(this::toMealLogResponse)
                .toList();
    }
}

