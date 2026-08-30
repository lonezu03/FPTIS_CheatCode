package com.fittrack.fitness.service;

import com.fittrack.FittrackBackendApplication;
import com.fittrack.nutrition.dto.CreateMealItemRequest;
import com.fittrack.nutrition.dto.CreateMealLogRequest;
import com.fittrack.nutrition.dto.UpdateMealItemRequest;
import com.fittrack.nutrition.dto.UpdateMealLogRequest;
import com.fittrack.nutrition.entity.Food;
import com.fittrack.nutrition.entity.NutritionDayStatus;
import com.fittrack.nutrition.repository.FoodRepository;
import com.fittrack.nutrition.service.NutritionService;
import com.fittrack.user.entity.User;
import com.fittrack.user.repository.UserRepository;
import com.fittrack.workout.dto.CreateWorkoutSessionRequest;
import com.fittrack.workout.dto.CreateWorkoutSetRequest;
import com.fittrack.workout.entity.Exercise;
import com.fittrack.workout.entity.WorkoutSetType;
import com.fittrack.workout.repository.ExerciseRepository;
import com.fittrack.workout.service.WorkoutService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertEquals;

@SpringBootTest(classes = FittrackBackendApplication.class)
@ActiveProfiles("test")
class FitnessHistoryIntegrationTest {

    @Autowired
    private WorkoutService workoutService;

    @Autowired
    private NutritionService nutritionService;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private ExerciseRepository exerciseRepository;

    @Autowired
    private FoodRepository foodRepository;

    @Test
    void workoutHistoryMapsSetsAndExercisesWithOpenInViewDisabled() {
        User user = saveUser("workout-history");
        Exercise exercise = exerciseRepository.save(Exercise.builder()
                .name("Dumbbell Shoulder Press")
                .muscleGroup("Shoulders")
                .equipment("Dumbbell")
                .build());

        CreateWorkoutSetRequest set = new CreateWorkoutSetRequest();
        set.setExerciseId(exercise.getId());
        set.setSetNumber(1);
        set.setExerciseOrder(1);
        set.setSetType(WorkoutSetType.WARMUP);
        set.setWeight(15.0);
        set.setReps(12);
        set.setRir(2);
        set.setRestSeconds(120);
        set.setCompleted(true);

        CreateWorkoutSessionRequest request = new CreateWorkoutSessionRequest();
        request.setSessionDate(LocalDate.of(2026, 8, 25));
        request.setDurationMinutes(45);
        request.setNote("Mobile history regression");
        request.setSets(List.of(set));
        workoutService.createSession(user, request);

        var history = assertDoesNotThrow(() -> workoutService.getMySessions(user));

        assertEquals(1, history.size());
        assertEquals(1, history.getFirst().getSets().size());
        assertEquals("Dumbbell Shoulder Press", history.getFirst().getSets().getFirst().getExerciseName());
        assertEquals(WorkoutSetType.WARMUP, history.getFirst().getSets().getFirst().getSetType());
        assertEquals(120, history.getFirst().getSets().getFirst().getRestSeconds());

        var previous = workoutService.getPreviousPerformance(user, exercise.getId());
        assertEquals(LocalDate.of(2026, 8, 25), previous.orElseThrow().getSessionDate());
        assertEquals(1, previous.orElseThrow().getSets().size());
    }

    @Test
    void mealHistoryMapsItemsAndFoodsWithOpenInViewDisabled() {
        User user = saveUser("meal-history");
        Food food = foodRepository.save(Food.builder()
                .name("Greek Yogurt")
                .unit("100g")
                .calories(59.0)
                .protein(10.0)
                .carbs(3.6)
                .fat(0.4)
                .build());

        CreateMealItemRequest item = new CreateMealItemRequest();
        item.setFoodId(food.getId());
        item.setQuantity(1.0);

        CreateMealLogRequest request = new CreateMealLogRequest();
        request.setMealType("BREAKFAST");
        request.setLogDate(LocalDate.of(2026, 8, 25));
        request.setItems(List.of(item));
        nutritionService.createMealLog(user, request);

        var history = assertDoesNotThrow(() -> nutritionService.getMyMealLogs(user));

        assertEquals(1, history.size());
        assertEquals(1, history.getFirst().getItems().size());
        assertEquals("Greek Yogurt", history.getFirst().getItems().getFirst().getFoodName());
    }

    @Test
    void nutritionDiaryKeepsPartialDaysOutOfTrustedDataAndConvertsGrams() {
        User user = saveUser("nutrition-diary");
        Food food = foodRepository.save(Food.builder()
                .name("Ức gà chín")
                .unit("100g")
                .servingSizeGrams(100.0)
                .calories(165.0)
                .protein(31.0)
                .carbs(0.0)
                .fat(3.6)
                .potassium(256.0)
                .build());

        CreateMealItemRequest item = new CreateMealItemRequest();
        item.setFoodId(food.getId());
        item.setServingAmount(150.0);
        item.setServingUnit("GRAM");

        CreateMealLogRequest request = new CreateMealLogRequest();
        request.setMealType("LUNCH");
        request.setLogDate(LocalDate.of(2026, 8, 30));
        request.setItems(List.of(item));
        nutritionService.createMealLog(user, request);

        var partialDiary = nutritionService.getDiary(user, request.getLogDate());
        assertEquals(NutritionDayStatus.PARTIAL, partialDiary.getStatus());
        assertEquals(247.5, partialDiary.getConsumed().getCalories(), 0.1);
        assertEquals(150.0,
                partialDiary.getMeals().getFirst().getItems().getFirst().getGramsEquivalent(),
                0.1);

        nutritionService.updateDayStatus(
                user,
                request.getLogDate(),
                NutritionDayStatus.COMPLETE
        );
        assertEquals(
                NutritionDayStatus.COMPLETE,
                nutritionService.getDiary(user, request.getLogDate()).getStatus()
        );
    }

    @Test
    void movingManualMealResetsQualityForBothDates() {
        User user = saveUser("nutrition-move-date");
        Food food = foodRepository.save(Food.builder()
                .name("Cơm trắng")
                .unit("100g")
                .servingSizeGrams(100.0)
                .calories(130.0)
                .protein(2.7)
                .carbs(28.0)
                .fat(0.3)
                .build());
        LocalDate oldDate = LocalDate.of(2026, 8, 28);
        LocalDate newDate = LocalDate.of(2026, 8, 29);

        CreateMealItemRequest createItem = new CreateMealItemRequest();
        createItem.setFoodId(food.getId());
        createItem.setQuantity(1.0);
        CreateMealLogRequest createRequest = new CreateMealLogRequest();
        createRequest.setMealType("LUNCH");
        createRequest.setLogDate(oldDate);
        createRequest.setItems(List.of(createItem));
        String mealId = nutritionService.createMealLog(user, createRequest).getId();
        nutritionService.updateDayStatus(user, oldDate, NutritionDayStatus.COMPLETE);

        UpdateMealItemRequest updateItem = new UpdateMealItemRequest();
        updateItem.setFoodId(food.getId());
        updateItem.setQuantity(1.0);
        UpdateMealLogRequest updateRequest = new UpdateMealLogRequest();
        updateRequest.setMealType("DINNER");
        updateRequest.setLogDate(newDate);
        updateRequest.setItems(List.of(updateItem));
        nutritionService.updateMealLog(user, mealId, updateRequest);

        assertEquals(NutritionDayStatus.UNLOGGED, nutritionService.getDiary(user, oldDate).getStatus());
        assertEquals(NutritionDayStatus.PARTIAL, nutritionService.getDiary(user, newDate).getStatus());
    }

    private User saveUser(String prefix) {
        return userRepository.save(User.builder()
                .email(prefix + "-" + UUID.randomUUID() + "@example.com")
                .password("encoded")
                .fullName(prefix)
                .role("USER")
                .fitnessEnabled(true)
                .build());
    }
}
