package com.fittrack.lunch.service;

import com.fittrack.lunch.entity.LunchMenuItem;
import com.fittrack.lunch.entity.LunchOrder;
import com.fittrack.lunch.entity.LunchOrderStatus;
import com.fittrack.nutrition.entity.Food;
import com.fittrack.nutrition.entity.MealItem;
import com.fittrack.nutrition.entity.MealLog;
import com.fittrack.nutrition.repository.FoodRepository;
import com.fittrack.nutrition.repository.MealLogRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class LunchNutritionService {

    private final FoodRepository foodRepository;
    private final MealLogRepository mealLogRepository;

    @Transactional
    public void syncOrder(LunchOrder order) {
        if (order.getStatus() != LunchOrderStatus.ACTIVE) {
            removeOrder(order.getId());
            return;
        }

        MealLog mealLog = mealLogRepository.findBySourceLunchOrderId(order.getId())
                .orElseGet(() -> MealLog.builder()
                        .sourceLunchOrderId(order.getId())
                        .items(new java.util.ArrayList<>())
                        .build());
        mealLog.setUser(order.getBeneficiary());
        mealLog.setMealType("LUNCH");
        mealLog.setLogDate(order.getMenu().getMenuDate());
        mealLog.setTotalCalories(0.0);
        mealLog.setTotalProtein(0.0);
        mealLog.setTotalCarbs(0.0);
        mealLog.setTotalFat(0.0);
        mealLog.getItems().clear();

        order.getItems().forEach(orderItem -> {
            LunchMenuItem menuItem = orderItem.getMenuItem();
            Food food = ensureFood(menuItem);
            double calories = zero(menuItem.getCalories());
            double protein = zero(menuItem.getProtein());
            double carbs = zero(menuItem.getCarbs());
            double fat = zero(menuItem.getFat());

            mealLog.getItems().add(MealItem.builder()
                    .mealLog(mealLog)
                    .food(food)
                    .quantity(1.0)
                    .calories(calories)
                    .protein(protein)
                    .carbs(carbs)
                    .fat(fat)
                    .fiber(0.0)
                    .sugar(0.0)
                    .sodium(0.0)
                    .potassium(0.0)
                    .calcium(0.0)
                    .iron(0.0)
                    .vitaminC(0.0)
                    .water(0.0)
                    .build());
            mealLog.setTotalCalories(mealLog.getTotalCalories() + calories);
            mealLog.setTotalProtein(mealLog.getTotalProtein() + protein);
            mealLog.setTotalCarbs(mealLog.getTotalCarbs() + carbs);
            mealLog.setTotalFat(mealLog.getTotalFat() + fat);
        });

        mealLogRepository.save(mealLog);
    }

    @Transactional
    public void removeOrder(String orderId) {
        mealLogRepository.findBySourceLunchOrderId(orderId)
                .ifPresent(mealLogRepository::delete);
    }

    @Transactional
    public Food ensureFood(LunchMenuItem item) {
        Food food = item.getNutritionFood();
        if (food == null) {
            food = Food.builder()
                    .name(item.getName())
                    .unit("1 phần")
                    .custom(true)
                    .active(true)
                    .build();
        }
        food.setName(item.getName());
        food.setImageUrl(item.getImageUrl());
        food.setCalories(zero(item.getCalories()));
        food.setProtein(zero(item.getProtein()));
        food.setCarbs(zero(item.getCarbs()));
        food.setFat(zero(item.getFat()));
        if (food.getApprovalStatus() == null) {
            food.setApprovalStatus("APPROVED");
        }
        Food saved = foodRepository.save(food);
        item.setNutritionFood(saved);
        return saved;
    }

    private double zero(Double value) {
        return value == null ? 0.0 : value;
    }
}
