package com.fittrack.nutrition.controller;

import com.fittrack.nutrition.dto.CreateMealLogRequest;
import com.fittrack.nutrition.dto.FoodResponse;
import com.fittrack.nutrition.dto.MealLogResponse;
import com.fittrack.nutrition.dto.UpdateMealLogRequest;
import com.fittrack.nutrition.service.FoodService;
import com.fittrack.nutrition.service.NutritionService;
import com.fittrack.user.entity.User;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;

@RestController
@RequestMapping("/api/nutrition")
@RequiredArgsConstructor
public class NutritionController {

    private final FoodService foodService;
    private final NutritionService nutritionService;

    @GetMapping("/foods")
    public List<FoodResponse> getFoods(
            @RequestParam(required = false) String keyword
    ) {
        return foodService.getFoods(keyword, false);
    }

    @PostMapping("/meal-logs")
    public MealLogResponse createMealLog(
            Authentication authentication,
            @RequestBody CreateMealLogRequest request
    ) {
        User user = (User) authentication.getPrincipal();

        return nutritionService.createMealLog(user, request);
    }

    @GetMapping("/meal-logs")
    public List<MealLogResponse> getMyMealLogs(
            Authentication authentication,
            @RequestParam(required = false) LocalDate date
    ) {
        User user = (User) authentication.getPrincipal();

        if (date != null) {
            return nutritionService.getMyMealLogsByDate(user, date);
        }

        return nutritionService.getMyMealLogs(user);
    }

    @PutMapping("/meal-logs/{id}")
    public MealLogResponse updateMealLog(
            Authentication authentication,
            @PathVariable String id,
            @RequestBody UpdateMealLogRequest request
    ) {
        User user = (User) authentication.getPrincipal();

        return nutritionService.updateMealLog(user, id, request);
    }

    @DeleteMapping("/meal-logs/{id}")
    public void deleteMealLog(
            Authentication authentication,
            @PathVariable String id
    ) {
        User user = (User) authentication.getPrincipal();

        nutritionService.deleteMealLog(user, id);
    }
}

