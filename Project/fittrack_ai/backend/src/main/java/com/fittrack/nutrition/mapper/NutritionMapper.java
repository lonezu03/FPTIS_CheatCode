package com.fittrack.nutrition.mapper;

import com.fittrack.nutrition.dto.FoodResponse;
import com.fittrack.nutrition.dto.MealItemResponse;
import com.fittrack.nutrition.dto.MealLogResponse;
import com.fittrack.nutrition.entity.Food;
import com.fittrack.nutrition.entity.MealItem;
import com.fittrack.nutrition.entity.MealLog;
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
                .unit(food.getUnit())
                .custom(food.getCustom())
                .active(food.getActive())
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
                .calories(item.getCalories())
                .protein(item.getProtein())
                .carbs(item.getCarbs())
                .fat(item.getFat())
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
                .createdAt(mealLog.getCreatedAt())
                .items(mealLog.getItems().stream()
                        .map(this::toMealItemResponse)
                        .toList())
                .build();
    }

    public List<MealLogResponse> toMealLogResponseList(List<MealLog> mealLogs) {
        return mealLogs.stream()
                .map(this::toMealLogResponse)
                .toList();
    }
}

