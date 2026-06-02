package com.fittrack.nutrition.service;

import com.fittrack.nutrition.dto.CreateMealItemRequest;
import com.fittrack.nutrition.dto.CreateMealLogRequest;
import com.fittrack.nutrition.dto.MealLogResponse;
import com.fittrack.nutrition.dto.UpdateMealItemRequest;
import com.fittrack.nutrition.dto.UpdateMealLogRequest;
import com.fittrack.nutrition.entity.Food;
import com.fittrack.nutrition.entity.MealItem;
import com.fittrack.nutrition.entity.MealLog;
import com.fittrack.nutrition.mapper.NutritionMapper;
import com.fittrack.nutrition.repository.FoodRepository;
import com.fittrack.nutrition.repository.MealLogRepository;
import com.fittrack.user.entity.User;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;

@Service
@RequiredArgsConstructor
public class NutritionService {

    private final FoodRepository foodRepository;
    private final MealLogRepository mealLogRepository;
    private final NutritionMapper nutritionMapper;

    @Transactional
    public MealLogResponse createMealLog(User user, CreateMealLogRequest request) {
        MealLog mealLog = MealLog.builder()
                .user(user)
                .mealType(request.getMealType())
                .logDate(request.getLogDate())
                .totalCalories(0.0)
                .totalProtein(0.0)
                .totalCarbs(0.0)
                .totalFat(0.0)
                .build();

        if (request.getItems() != null) {
            for (CreateMealItemRequest itemRequest : request.getItems()) {
                Food food = findActiveFood(itemRequest.getFoodId());

                double quantity = itemRequest.getQuantity() == null ? 1.0 : itemRequest.getQuantity();

                double calories = defaultZero(food.getCalories()) * quantity;
                double protein = defaultZero(food.getProtein()) * quantity;
                double carbs = defaultZero(food.getCarbs()) * quantity;
                double fat = defaultZero(food.getFat()) * quantity;

                MealItem item = MealItem.builder()
                        .mealLog(mealLog)
                        .food(food)
                        .quantity(quantity)
                        .calories(calories)
                        .protein(protein)
                        .carbs(carbs)
                        .fat(fat)
                        .build();

                mealLog.getItems().add(item);

                mealLog.setTotalCalories(mealLog.getTotalCalories() + calories);
                mealLog.setTotalProtein(mealLog.getTotalProtein() + protein);
                mealLog.setTotalCarbs(mealLog.getTotalCarbs() + carbs);
                mealLog.setTotalFat(mealLog.getTotalFat() + fat);
            }
        }

        MealLog savedMealLog = mealLogRepository.save(mealLog);

        return nutritionMapper.toMealLogResponse(savedMealLog);
    }

    public List<MealLogResponse> getMyMealLogsByDate(User user, LocalDate date) {
        return nutritionMapper.toMealLogResponseList(
                mealLogRepository.findByUserAndLogDateOrderByCreatedAtDesc(user, date)
        );
    }

    public List<MealLogResponse> getMyMealLogs(User user) {
        return nutritionMapper.toMealLogResponseList(
                mealLogRepository.findByUserOrderByLogDateDesc(user)
        );
    }

    @Transactional
    public void deleteMealLog(User user, String mealLogId) {
        MealLog mealLog = mealLogRepository.findByIdAndUser(mealLogId, user)
                .orElseThrow(() -> new IllegalArgumentException("Meal log not found"));

        mealLogRepository.delete(mealLog);
    }

    @Transactional
    public MealLogResponse updateMealLog(
            User user,
            String mealLogId,
            UpdateMealLogRequest request
    ) {
        MealLog mealLog = mealLogRepository.findByIdAndUser(mealLogId, user)
                .orElseThrow(() -> new IllegalArgumentException("Meal log not found"));

        mealLog.setMealType(request.getMealType());
        mealLog.setLogDate(request.getLogDate());

        mealLog.getItems().clear();

        mealLog.setTotalCalories(0.0);
        mealLog.setTotalProtein(0.0);
        mealLog.setTotalCarbs(0.0);
        mealLog.setTotalFat(0.0);

        if (request.getItems() != null) {
            for (UpdateMealItemRequest itemRequest : request.getItems()) {
                Food food = findActiveFood(itemRequest.getFoodId());

                double quantity = itemRequest.getQuantity() == null ? 1.0 : itemRequest.getQuantity();

                double calories = defaultZero(food.getCalories()) * quantity;
                double protein = defaultZero(food.getProtein()) * quantity;
                double carbs = defaultZero(food.getCarbs()) * quantity;
                double fat = defaultZero(food.getFat()) * quantity;

                MealItem item = MealItem.builder()
                        .mealLog(mealLog)
                        .food(food)
                        .quantity(quantity)
                        .calories(calories)
                        .protein(protein)
                        .carbs(carbs)
                        .fat(fat)
                        .build();

                mealLog.getItems().add(item);

                mealLog.setTotalCalories(mealLog.getTotalCalories() + calories);
                mealLog.setTotalProtein(mealLog.getTotalProtein() + protein);
                mealLog.setTotalCarbs(mealLog.getTotalCarbs() + carbs);
                mealLog.setTotalFat(mealLog.getTotalFat() + fat);
            }
        }

        MealLog saved = mealLogRepository.save(mealLog);

        return nutritionMapper.toMealLogResponse(saved);
    }

    private Food findActiveFood(String foodId) {
        Food food = foodRepository.findById(foodId)
                .orElseThrow(() -> new IllegalArgumentException("Food not found"));

        if (Boolean.FALSE.equals(food.getActive())) {
            throw new IllegalArgumentException("Food is inactive");
        }

        return food;
    }

    private double defaultZero(Double value) {
        return value == null ? 0.0 : value;
    }
}

