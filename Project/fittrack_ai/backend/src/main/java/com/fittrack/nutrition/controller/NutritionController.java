package com.fittrack.nutrition.controller;

import com.fittrack.nutrition.dto.CreateMealLogRequest;
import com.fittrack.nutrition.dto.FoodResponse;
import com.fittrack.nutrition.dto.MealLogResponse;
import com.fittrack.nutrition.dto.UpdateMealLogRequest;
import com.fittrack.nutrition.dto.NutritionDayStatusRequest;
import com.fittrack.nutrition.dto.NutritionDiaryResponse;
import com.fittrack.nutrition.dto.WaterLogRequest;
import com.fittrack.nutrition.dto.WaterLogResponse;
import com.fittrack.nutrition.service.FoodService;
import com.fittrack.nutrition.service.NutritionService;
import com.fittrack.nutrition.service.WaterLogService;
import com.fittrack.user.entity.User;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import com.fittrack.common.dto.PageResponse;

@RestController
@RequestMapping("/api/nutrition")
@RequiredArgsConstructor
public class NutritionController {

    private final FoodService foodService;
    private final NutritionService nutritionService;
    private final WaterLogService waterLogService;

    @GetMapping("/foods")
    public List<FoodResponse> getFoods(
            @RequestParam(required = false) String keyword
    ) {
        return foodService.getFoods(keyword, false);
    }

    @PostMapping("/meal-logs")
    public MealLogResponse createMealLog(
            Authentication authentication,
            @Valid @RequestBody CreateMealLogRequest request
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

    @GetMapping("/diary")
    public NutritionDiaryResponse getDiary(
            Authentication authentication,
            @RequestParam(required = false) LocalDate date
    ) {
        return nutritionService.getDiary((User) authentication.getPrincipal(), date);
    }

    @PutMapping("/days/{date}/status")
    public NutritionDiaryResponse updateDayStatus(
            Authentication authentication,
            @PathVariable LocalDate date,
            @Valid @RequestBody NutritionDayStatusRequest request
    ) {
        User user = (User) authentication.getPrincipal();
        nutritionService.updateDayStatus(user, date, request.getStatus());
        return nutritionService.getDiary(user, date);
    }

    @GetMapping("/water-logs")
    public List<WaterLogResponse> getWaterLogs(
            Authentication authentication,
            @RequestParam(required = false) LocalDate date
    ) {
        return waterLogService.getByDate(
                (User) authentication.getPrincipal(),
                date == null ? LocalDate.now() : date
        );
    }

    @PostMapping("/water-logs")
    public WaterLogResponse createWaterLog(
            Authentication authentication,
            @Valid @RequestBody WaterLogRequest request
    ) {
        return waterLogService.create((User) authentication.getPrincipal(), request);
    }

    @DeleteMapping("/water-logs/{id}")
    public void deleteWaterLog(Authentication authentication, @PathVariable String id) {
        waterLogService.delete((User) authentication.getPrincipal(), id);
    }

    @GetMapping("/meal-logs/page")
    public PageResponse<MealLogResponse> getMealLogsPage(
            Authentication authentication,
            @RequestParam(required = false) LocalDate date,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size
    ) {
        return nutritionService.getMyMealLogsPage(
                (User) authentication.getPrincipal(), date, page, size
        );
    }

    @PutMapping("/meal-logs/{id}")
    public MealLogResponse updateMealLog(
            Authentication authentication,
            @PathVariable String id,
            @Valid @RequestBody UpdateMealLogRequest request
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

