package com.fittrack.nutrition.service;

import com.fittrack.nutrition.dto.CreateFoodRequest;
import com.fittrack.nutrition.dto.FoodResponse;
import com.fittrack.nutrition.dto.UpdateFoodRequest;
import com.fittrack.nutrition.entity.Food;
import com.fittrack.nutrition.mapper.NutritionMapper;
import com.fittrack.nutrition.repository.FoodRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class FoodService {

    private final FoodRepository foodRepository;
    private final NutritionMapper nutritionMapper;

    public List<FoodResponse> getFoods(String keyword, Boolean includeInactive) {
        boolean showInactive = Boolean.TRUE.equals(includeInactive);

        List<Food> foods;

        if (showInactive) {
            if (keyword == null || keyword.isBlank()) {
                foods = foodRepository.findAllByOrderByNameAsc();
            } else {
                foods = foodRepository.findByNameContainingIgnoreCaseOrderByNameAsc(keyword);
            }
        } else {
            if (keyword == null || keyword.isBlank()) {
                foods = foodRepository.findByActiveTrueOrderByNameAsc();
            } else {
                foods = foodRepository.findByActiveTrueAndNameContainingIgnoreCaseOrderByNameAsc(keyword);
            }
        }

        return nutritionMapper.toFoodResponseList(foods);
    }

    public FoodResponse create(CreateFoodRequest request) {
        Food food = Food.builder()
                .name(request.getName())
                .calories(defaultZero(request.getCalories()))
                .protein(defaultZero(request.getProtein()))
                .carbs(defaultZero(request.getCarbs()))
                .fat(defaultZero(request.getFat()))
                .unit(request.getUnit())
                .custom(true)
                .active(true)
                .build();

        Food saved = foodRepository.save(food);

        return nutritionMapper.toFoodResponse(saved);
    }

    public FoodResponse update(String id, UpdateFoodRequest request) {
        Food food = foodRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Food not found"));

        food.setName(request.getName());
        food.setCalories(defaultZero(request.getCalories()));
        food.setProtein(defaultZero(request.getProtein()));
        food.setCarbs(defaultZero(request.getCarbs()));
        food.setFat(defaultZero(request.getFat()));
        food.setUnit(request.getUnit());

        Food saved = foodRepository.save(food);

        return nutritionMapper.toFoodResponse(saved);
    }

    public void softDelete(String id) {
        Food food = foodRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Food not found"));

        food.setActive(false);

        foodRepository.save(food);
    }

    public FoodResponse restore(String id) {
        Food food = foodRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Food not found"));

        food.setActive(true);

        Food saved = foodRepository.save(food);

        return nutritionMapper.toFoodResponse(saved);
    }

    private double defaultZero(Double value) {
        return value == null ? 0.0 : value;
    }
}

