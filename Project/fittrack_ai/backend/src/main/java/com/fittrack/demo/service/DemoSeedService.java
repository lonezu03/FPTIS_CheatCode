package com.fittrack.demo.service;

import com.fittrack.bodytracking.entity.BodyMeasurement;
import com.fittrack.bodytracking.repository.BodyMeasurementRepository;
import com.fittrack.demo.dto.DemoSeedResponse;
import com.fittrack.nutrition.entity.Food;
import com.fittrack.nutrition.entity.MealItem;
import com.fittrack.nutrition.entity.MealLog;
import com.fittrack.nutrition.repository.FoodRepository;
import com.fittrack.nutrition.repository.MealLogRepository;
import com.fittrack.user.entity.User;
import com.fittrack.workout.entity.Exercise;
import com.fittrack.workout.entity.WorkoutSession;
import com.fittrack.workout.entity.WorkoutSet;
import com.fittrack.workout.repository.ExerciseRepository;
import com.fittrack.workout.repository.WorkoutSessionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.List;

@Service
@RequiredArgsConstructor
public class DemoSeedService {

    private final FoodRepository foodRepository;
    private final MealLogRepository mealLogRepository;
    private final ExerciseRepository exerciseRepository;
    private final WorkoutSessionRepository workoutSessionRepository;
    private final BodyMeasurementRepository bodyMeasurementRepository;

    public DemoSeedResponse seed(User user) {
        int foodsCreated = seedFoods();
        int exercisesCreated = seedExercises();

        List<Food> foods = foodRepository.findByActiveTrueOrderByNameAsc();
        List<Exercise> exercises = exerciseRepository.findByActiveTrueOrderByNameAsc();

        int mealLogsCreated = seedMealLogs(user, foods);
        int workoutSessionsCreated = seedWorkoutSessions(user, exercises);
        int bodyMeasurementsCreated = seedBodyMeasurements(user);

        return DemoSeedResponse.builder()
                .message("Demo data seeded successfully")
                .foodsCreated(foodsCreated)
                .exercisesCreated(exercisesCreated)
                .mealLogsCreated(mealLogsCreated)
                .workoutSessionsCreated(workoutSessionsCreated)
                .bodyMeasurementsCreated(bodyMeasurementsCreated)
                .build();
    }

    private int seedFoods() {
        int count = 0;

        count += createFoodIfMissing("Chicken Breast", 165.0, 31.0, 0.0, 3.6, "100g");
        count += createFoodIfMissing("White Rice", 130.0, 2.7, 28.0, 0.3, "100g");
        count += createFoodIfMissing("Egg", 70.0, 6.0, 0.6, 5.0, "1 egg");
        count += createFoodIfMissing("Sweet Potato", 86.0, 1.6, 20.0, 0.1, "100g");
        count += createFoodIfMissing("Greek Yogurt", 59.0, 10.0, 3.6, 0.4, "100g");
        count += createFoodIfMissing("Banana", 89.0, 1.1, 23.0, 0.3, "100g");

        return count;
    }

    private int createFoodIfMissing(
            String name,
            Double calories,
            Double protein,
            Double carbs,
            Double fat,
            String unit
    ) {
        boolean exists = foodRepository.findByNameContainingIgnoreCaseOrderByNameAsc(name)
                .stream()
                .anyMatch(food -> food.getName().equalsIgnoreCase(name));

        if (exists) return 0;

        foodRepository.save(Food.builder()
                .name(name)
                .calories(calories)
                .protein(protein)
                .carbs(carbs)
                .fat(fat)
                .unit(unit)
                .custom(false)
                .active(true)
                .build());

        return 1;
    }

    private int seedExercises() {
        int count = 0;

        count += createExerciseIfMissing("Dumbbell Shoulder Press", "Shoulder", "Dumbbell");
        count += createExerciseIfMissing("Dumbbell Squat", "Legs", "Dumbbell");
        count += createExerciseIfMissing("Pull Up", "Back", "Pull-up Bar");
        count += createExerciseIfMissing("Push Up", "Chest", "Bodyweight");
        count += createExerciseIfMissing("Ring Row", "Back", "Rings");
        count += createExerciseIfMissing("Bulgarian Split Squat", "Legs", "Dumbbell");

        return count;
    }

    private int createExerciseIfMissing(String name, String muscleGroup, String equipment) {
        boolean exists = exerciseRepository.findByNameContainingIgnoreCaseOrderByNameAsc(name)
                .stream()
                .anyMatch(exercise -> exercise.getName().equalsIgnoreCase(name));

        if (exists) return 0;

        exerciseRepository.save(Exercise.builder()
                .name(name)
                .muscleGroup(muscleGroup)
                .equipment(equipment)
                .description("Demo exercise")
                .custom(false)
                .active(true)
                .build());

        return 1;
    }

    private int seedMealLogs(User user, List<Food> foods) {
        if (foods.isEmpty()) return 0;

        int created = 0;
        LocalDate today = LocalDate.now();

        for (int i = 6; i >= 0; i--) {
            LocalDate date = today.minusDays(i);

            if (!mealLogRepository.findByUserAndLogDate(user, date).isEmpty()) {
                continue;
            }

            MealLog breakfast = createMealLog(user, date, "BREAKFAST");
            addFoodItem(breakfast, findFood(foods, "Egg"), 2.0);
            addFoodItem(breakfast, findFood(foods, "Banana"), 1.0);
            mealLogRepository.save(breakfast);

            MealLog lunch = createMealLog(user, date, "LUNCH");
            addFoodItem(lunch, findFood(foods, "Chicken Breast"), 2.0);
            addFoodItem(lunch, findFood(foods, "White Rice"), 3.0);
            mealLogRepository.save(lunch);

            MealLog dinner = createMealLog(user, date, "DINNER");
            addFoodItem(dinner, findFood(foods, "Greek Yogurt"), 2.0);
            addFoodItem(dinner, findFood(foods, "Sweet Potato"), 2.0);
            mealLogRepository.save(dinner);

            created += 3;
        }

        return created;
    }

    private MealLog createMealLog(User user, LocalDate date, String mealType) {
        return MealLog.builder()
                .user(user)
                .mealType(mealType)
                .logDate(date)
                .totalCalories(0.0)
                .totalProtein(0.0)
                .totalCarbs(0.0)
                .totalFat(0.0)
                .build();
    }

    private void addFoodItem(MealLog mealLog, Food food, Double quantity) {
        if (food == null) return;

        double calories = (food.getCalories() == null ? 0.0 : food.getCalories()) * quantity;
        double protein = (food.getProtein() == null ? 0.0 : food.getProtein()) * quantity;
        double carbs = (food.getCarbs() == null ? 0.0 : food.getCarbs()) * quantity;
        double fat = (food.getFat() == null ? 0.0 : food.getFat()) * quantity;

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

    private Food findFood(List<Food> foods, String name) {
        return foods.stream()
                .filter(food -> food.getName().equalsIgnoreCase(name))
                .findFirst()
                .orElse(foods.get(0));
    }

    private int seedWorkoutSessions(User user, List<Exercise> exercises) {
        if (exercises.isEmpty()) return 0;

        int created = 0;
        LocalDate today = LocalDate.now();

        for (int i = 0; i < 7; i += 2) {
            LocalDate date = today.minusDays(i);

            if (!workoutSessionRepository.findByUserAndSessionDateOrderByCreatedAtDesc(user, date).isEmpty()) {
                continue;
            }

            WorkoutSession session = WorkoutSession.builder()
                    .user(user)
                    .sessionDate(date)
                    .note("Demo workout session")
                    .durationMinutes(60)
                    .build();

            Exercise first = exercises.get(0);
            Exercise second = exercises.size() > 1 ? exercises.get(1) : exercises.get(0);

            addWorkoutSets(session, first, 3, 10, 9.0, 2);
            addWorkoutSets(session, second, 3, 12, 15.0, 2);

            workoutSessionRepository.save(session);
            created++;
        }

        return created;
    }

    private void addWorkoutSets(
            WorkoutSession session,
            Exercise exercise,
            int sets,
            int reps,
            double weight,
            int rir
    ) {
        for (int i = 1; i <= sets; i++) {
            WorkoutSet set = WorkoutSet.builder()
                    .session(session)
                    .exercise(exercise)
                    .setNumber(i)
                    .reps(reps)
                    .weight(weight)
                    .rir(rir)
                    .build();

            session.getSets().add(set);
        }
    }

    private int seedBodyMeasurements(User user) {
        int created = 0;
        LocalDate today = LocalDate.now();

        List<BodyMeasurement> existing =
                bodyMeasurementRepository.findByUserAndRecordDateBetweenOrderByRecordDateAsc(
                        user,
                        today.minusDays(6),
                        today
                );

        if (!existing.isEmpty()) return 0;

        bodyMeasurementRepository.save(BodyMeasurement.builder()
                .user(user)
                .recordDate(today.minusDays(6))
                .weight(60.0)
                .waist(78.0)
                .chest(90.0)
                .arm(30.0)
                .thigh(52.0)
                .build());

        bodyMeasurementRepository.save(BodyMeasurement.builder()
                .user(user)
                .recordDate(today)
                .weight(60.4)
                .waist(77.5)
                .chest(91.0)
                .arm(30.5)
                .thigh(52.5)
                .build());

        created += 2;

        return created;
    }
}

