package com.fittrack.assistant.service;

import com.fittrack.common.exception.ExternalServiceException;
import com.fittrack.lunch.service.LunchService;
import com.fittrack.lunch.dto.LunchDtos.OrderResponse;
import com.fittrack.lunch.dto.LunchDtos.TodayResponse;
import com.fittrack.nutrition.entity.Food;
import com.fittrack.nutrition.repository.FoodRepository;
import com.fittrack.nutrition.service.NutritionService;
import com.fittrack.user.entity.User;
import com.fittrack.user.mapper.UserMapper;
import com.fittrack.workout.entity.Exercise;
import com.fittrack.workout.repository.ExerciseRepository;
import com.fittrack.workout.service.WorkoutService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.ZoneId;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import tools.jackson.core.JacksonException;
import tools.jackson.databind.ObjectMapper;

@Service
@RequiredArgsConstructor
public class AssistantContextService {

    private static final ZoneId BUSINESS_ZONE = ZoneId.of("Asia/Ho_Chi_Minh");

    private final ObjectMapper objectMapper;
    private final UserMapper userMapper;
    private final ExerciseRepository exerciseRepository;
    private final FoodRepository foodRepository;
    private final WorkoutService workoutService;
    private final NutritionService nutritionService;
    private final LunchService lunchService;

    @Transactional(readOnly = true)
    public String buildContext(User user) {
        var profile = userMapper.toProfileResponse(user);
        TodayResponse today = lunchService.getToday(user);
        Map<String, Object> context = new LinkedHashMap<>();
        context.put("currentDate", LocalDate.now(BUSINESS_ZONE));
        context.put("profile", Map.ofEntries(
                Map.entry("fullName", valueOrEmpty(profile.getFullName())),
                Map.entry("gender", valueOrEmpty(profile.getGender())),
                Map.entry("age", valueOrZero(profile.getAge())),
                Map.entry("height", valueOrZero(profile.getHeight())),
                Map.entry("weight", valueOrZero(profile.getWeight())),
                Map.entry("goal", valueOrEmpty(profile.getGoal())),
                Map.entry("activityLevel", valueOrEmpty(profile.getActivityLevel())),
                Map.entry("targetCalories", valueOrZero(profile.getTargetCalories())),
                Map.entry("targetProtein", valueOrZero(profile.getTargetProtein())),
                Map.entry("targetCarbs", valueOrZero(profile.getTargetCarbs())),
                Map.entry("targetFat", valueOrZero(profile.getTargetFat()))
        ));
        context.put("todayLunch", todayContext(today));
        context.put(
                "peopleAvailableForLunchOrder",
                lunchService.getPeople(user).stream()
                        .map(person -> Map.of(
                                "id", person.id(),
                                "fullName", valueOrEmpty(person.fullName())
                        ))
                        .toList()
        );
        context.put(
                "exerciseCatalog",
                exerciseRepository.findByActiveTrueOrderByNameAsc()
                        .stream()
                        .map(this::exerciseContext)
                        .toList()
        );
        context.put(
                "foodCatalog",
                foodRepository.findByActiveTrueOrderByNameAsc()
                        .stream()
                        .map(this::foodContext)
                        .toList()
        );
        context.put(
                "recentWorkoutSessions",
                workoutService.getMySessions(user).stream().limit(10).toList()
        );
        context.put(
                "recentMealLogs",
                nutritionService.getMyMealLogs(user).stream().limit(10).toList()
        );

        try {
            return objectMapper.writeValueAsString(context);
        } catch (JacksonException exception) {
            throw new ExternalServiceException(
                    "Không thể chuẩn bị dữ liệu cho trợ lý",
                    exception
            );
        }
    }

    private Map<String, Object> exerciseContext(Exercise exercise) {
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("id", exercise.getId());
        result.put("name", exercise.getName());
        result.put("muscleGroup", exercise.getMuscleGroup());
        result.put("equipment", exercise.getEquipment());
        result.put("description", exercise.getDescription());
        return result;
    }

    private Map<String, Object> foodContext(Food food) {
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("id", food.getId());
        result.put("name", food.getName());
        result.put("unit", food.getUnit());
        result.put("calories", food.getCalories());
        result.put("protein", food.getProtein());
        result.put("carbs", food.getCarbs());
        result.put("fat", food.getFat());
        return result;
    }

    private Map<String, Object> todayContext(TodayResponse today) {
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("menu", today.menu());
        result.put("walletBalance", today.walletBalance());
        result.put("outstandingDebt", today.outstandingDebt());
        result.put("canOrder", today.canOrder());
        result.put("blockReason", today.blockReason());
        result.put(
                "myMealOrder",
                today.myMealOrder() == null ? null : orderContext(today.myMealOrder())
        );
        result.put(
                "ordersPlacedByMe",
                today.ordersPlacedByMe().stream().map(this::orderContext).toList()
        );
        return result;
    }

    private Map<String, Object> orderContext(OrderResponse order) {
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("id", order.id());
        result.put("beneficiaryId", order.beneficiary().id());
        result.put("beneficiaryName", order.beneficiary().fullName());
        result.put("selectionType", order.selectionType());
        result.put("items", order.items());
        result.put("note", order.note());
        result.put("paymentStatus", order.paymentStatus());
        result.put("status", order.status());
        return result;
    }

    private Object valueOrZero(Object value) {
        return value == null ? 0 : value;
    }

    private String valueOrEmpty(String value) {
        return value == null ? "" : value;
    }
}
