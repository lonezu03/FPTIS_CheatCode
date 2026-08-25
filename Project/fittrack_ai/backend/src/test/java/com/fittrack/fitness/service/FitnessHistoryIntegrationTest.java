package com.fittrack.fitness.service;

import com.fittrack.FittrackBackendApplication;
import com.fittrack.nutrition.dto.CreateMealItemRequest;
import com.fittrack.nutrition.dto.CreateMealLogRequest;
import com.fittrack.nutrition.entity.Food;
import com.fittrack.nutrition.repository.FoodRepository;
import com.fittrack.nutrition.service.NutritionService;
import com.fittrack.user.entity.User;
import com.fittrack.user.repository.UserRepository;
import com.fittrack.workout.dto.CreateWorkoutSessionRequest;
import com.fittrack.workout.dto.CreateWorkoutSetRequest;
import com.fittrack.workout.entity.Exercise;
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
        set.setWeight(15.0);
        set.setReps(12);
        set.setRir(2);

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
