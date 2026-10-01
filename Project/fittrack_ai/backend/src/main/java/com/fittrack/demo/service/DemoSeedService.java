package com.fittrack.demo.service;

import com.fittrack.bodytracking.entity.BodyMeasurement;
import com.fittrack.bodytracking.repository.BodyMeasurementRepository;
import com.fittrack.demo.dto.DemoSeedResponse;
import com.fittrack.nutrition.entity.Food;
import com.fittrack.nutrition.entity.MealItem;
import com.fittrack.nutrition.entity.MealLog;
import com.fittrack.nutrition.repository.FoodRepository;
import com.fittrack.nutrition.repository.MealLogRepository;
import com.fittrack.common.exception.ConflictException;
import com.fittrack.quote.dto.QuoteDtos.QuoteRequest;
import com.fittrack.quote.entity.QuoteSourceType;
import com.fittrack.quote.service.QuoteService;
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
    private final QuoteService quoteService;

    public DemoSeedResponse seed(User user) {
        int foodsCreated = seedFoods();
        int exercisesCreated = seedExercises();

        List<Food> foods = foodRepository.findByActiveTrueOrderByNameAsc();
        List<Exercise> exercises = exerciseRepository.findByActiveTrueOrderByNameAsc();

        int mealLogsCreated = seedMealLogs(user, foods);
        int workoutSessionsCreated = seedWorkoutSessions(user, exercises);
        int bodyMeasurementsCreated = seedBodyMeasurements(user);
        int quotesCreated = seedFavoriteQuotes(user);

        return DemoSeedResponse.builder()
                .message("Đã bổ sung dữ liệu mẫu cho tài khoản")
                .foodsCreated(foodsCreated)
                .exercisesCreated(exercisesCreated)
                .mealLogsCreated(mealLogsCreated)
                .workoutSessionsCreated(workoutSessionsCreated)
                .bodyMeasurementsCreated(bodyMeasurementsCreated)
                .quotesCreated(quotesCreated)
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
        count += createExerciseIfMissing("Barbell Bench Press", "Chest", "Barbell");
        count += createExerciseIfMissing("Incline Dumbbell Bench Press", "Chest", "Dumbbell");
        count += createExerciseIfMissing("Shoulder Press Machine", "Shoulder", "Shoulder Press Machine");
        count += createExerciseIfMissing("Triceps Pushdown", "Triceps", "Cable Machine");
        count += createExerciseIfMissing("Lat Pulldown", "Back", "Lat Pulldown Machine");
        count += createExerciseIfMissing("Seated Cable Row", "Back", "Cable Machine");
        count += createExerciseIfMissing("Barbell Biceps Curl", "Biceps", "Barbell");
        count += createExerciseIfMissing("Smith Machine Squat", "Legs", "Smith Machine");
        count += createExerciseIfMissing("Leg Press Machine", "Legs", "Leg Press Machine");
        count += createExerciseIfMissing("Seated Leg Curl Machine", "Legs", "Leg Curl Machine");
        count += createExerciseIfMissing("Romanian Deadlift", "Legs", "Barbell");
        count += createExerciseIfMissing("Cable Crossover", "Chest", "Cable Machine");

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

        List<WorkoutTemplate> templates = List.of(
                new WorkoutTemplate(0, "Buổi đẩy mẫu · Ngực, vai, tay sau", 65, List.of(
                        new ExerciseTemplate("Barbell Bench Press", 3, 8, 40.0, 2),
                        new ExerciseTemplate("Incline Dumbbell Bench Press", 3, 10, 14.0, 2),
                        new ExerciseTemplate("Shoulder Press Machine", 3, 10, 25.0, 2),
                        new ExerciseTemplate("Triceps Pushdown", 3, 12, 20.0, 2)
                )),
                new WorkoutTemplate(2, "Buổi kéo mẫu · Lưng, tay trước", 60, List.of(
                        new ExerciseTemplate("Lat Pulldown", 3, 10, 35.0, 2),
                        new ExerciseTemplate("Seated Cable Row", 3, 10, 35.0, 2),
                        new ExerciseTemplate("Barbell Biceps Curl", 3, 12, 15.0, 2)
                )),
                new WorkoutTemplate(4, "Buổi chân mẫu · Đùi trước, đùi sau, mông", 70, List.of(
                        new ExerciseTemplate("Smith Machine Squat", 4, 8, 50.0, 2),
                        new ExerciseTemplate("Leg Press Machine", 3, 12, 80.0, 2),
                        new ExerciseTemplate("Seated Leg Curl Machine", 3, 12, 30.0, 2),
                        new ExerciseTemplate("Romanian Deadlift", 3, 10, 40.0, 2)
                )),
                new WorkoutTemplate(6, "Buổi thân trên mẫu · Kỹ thuật và kiểm soát", 55, List.of(
                        new ExerciseTemplate("Incline Dumbbell Bench Press", 3, 12, 12.0, 3),
                        new ExerciseTemplate("Lat Pulldown", 3, 12, 30.0, 3),
                        new ExerciseTemplate("Cable Crossover", 3, 15, 10.0, 2)
                ))
        );

        for (WorkoutTemplate template : templates) {
            LocalDate date = today.minusDays(template.daysAgo());

            if (!workoutSessionRepository.findByUserAndSessionDateOrderByCreatedAtDesc(user, date).isEmpty()) {
                continue;
            }

            WorkoutSession session = WorkoutSession.builder()
                    .user(user)
                    .sessionDate(date)
                    .note(template.note())
                    .durationMinutes(template.durationMinutes())
                    .build();

            int exerciseOrder = 1;
            for (ExerciseTemplate item : template.exercises()) {
                Exercise exercise = findExercise(exercises, item.name());
                if (exercise == null) continue;
                addWorkoutSets(
                        session,
                        exercise,
                        exerciseOrder++,
                        item.sets(),
                        item.reps(),
                        item.weight(),
                        item.rir()
                );
            }
            if (session.getSets().isEmpty()) continue;

            workoutSessionRepository.save(session);
            created++;
        }

        return created;
    }

    private void addWorkoutSets(
            WorkoutSession session,
            Exercise exercise,
            int exerciseOrder,
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
                    .exerciseOrder(exerciseOrder)
                    .reps(reps)
                    .weight(weight)
                    .rir(rir)
                    .build();

            session.getSets().add(set);
        }
    }

    private Exercise findExercise(List<Exercise> exercises, String name) {
        return exercises.stream()
                .filter(exercise -> exercise.getName().equalsIgnoreCase(name))
                .findFirst()
                .orElse(null);
    }

    private int seedFavoriteQuotes(User user) {
        List<QuoteSeed> seeds = List.of(
                new QuoteSeed("Kỷ luật là cây cầu nối giữa mục tiêu và thành tựu.", "Jim Rohn", "Kỷ luật", List.of("kỷ-luật", "mục-tiêu")),
                new QuoteSeed("Bạn không cần hoàn hảo để bắt đầu, nhưng cần bắt đầu để tiến bộ.", null, "FitTrack", List.of("bắt-đầu", "tiến-bộ")),
                new QuoteSeed("Chậm vẫn là tiến lên, miễn là bạn không dừng lại.", null, "FitTrack", List.of("kiên-trì")),
                new QuoteSeed("Mỗi buổi tập là một lá phiếu cho con người bạn muốn trở thành.", null, "FitTrack", List.of("luyện-tập", "thói-quen")),
                new QuoteSeed("Sức khỏe tốt được xây từ những lựa chọn nhỏ lặp lại mỗi ngày.", null, "FitTrack", List.of("sức-khỏe", "hằng-ngày")),
                new QuoteSeed("Hãy tập trung vào điều bạn có thể làm hôm nay.", null, "FitTrack", List.of("tập-trung")),
                new QuoteSeed("Nghỉ ngơi đúng lúc cũng là một phần của tiến bộ.", null, "FitTrack", List.of("phục-hồi")),
                new QuoteSeed("Đừng so sánh chương đầu của mình với chương hai mươi của người khác.", null, "FitTrack", List.of("tự-tin", "hành-trình"))
        );
        int created = 0;
        for (QuoteSeed seed : seeds) {
            try {
                quoteService.create(user, new QuoteRequest(
                        seed.content(),
                        seed.author(),
                        QuoteSourceType.OTHER,
                        seed.sourceTitle(),
                        null,
                        null,
                        "Dữ liệu mẫu; bạn có thể sửa hoặc xóa.",
                        true,
                        "vi",
                        seed.tags(),
                        false
                ));
                created++;
            } catch (ConflictException ignored) {
                // Dữ liệu mẫu phải idempotent khi người dùng nhấn lại.
            }
        }
        return created;
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

    private record WorkoutTemplate(
            int daysAgo,
            String note,
            int durationMinutes,
            List<ExerciseTemplate> exercises
    ) {
    }

    private record ExerciseTemplate(
            String name,
            int sets,
            int reps,
            double weight,
            int rir
    ) {
    }

    private record QuoteSeed(
            String content,
            String author,
            String sourceTitle,
            List<String> tags
    ) {
    }
}

