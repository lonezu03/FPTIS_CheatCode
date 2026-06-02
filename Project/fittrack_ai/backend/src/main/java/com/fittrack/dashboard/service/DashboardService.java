package com.fittrack.dashboard.service;

import com.fittrack.bodytracking.entity.BodyMeasurement;
import com.fittrack.bodytracking.repository.BodyMeasurementRepository;
import com.fittrack.dashboard.dto.DashboardProgressResponse;
import com.fittrack.dashboard.dto.DashboardTodayResponse;
import com.fittrack.dashboard.dto.ProgressPointResponse;
import com.fittrack.nutrition.entity.MealLog;
import com.fittrack.nutrition.repository.MealLogRepository;
import com.fittrack.user.entity.User;
import com.fittrack.user.service.GoalCalculatorService;
import com.fittrack.workout.entity.WorkoutSession;
import com.fittrack.workout.repository.WorkoutSessionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class DashboardService {

    private final BodyMeasurementRepository bodyMeasurementRepository;
    private final MealLogRepository mealLogRepository;
    private final WorkoutSessionRepository workoutSessionRepository;
    private final GoalCalculatorService goalCalculatorService;

    public DashboardTodayResponse getTodayDashboard(User user) {
        LocalDate today = LocalDate.now();

        List<MealLog> meals = mealLogRepository.findByUserAndLogDate(user, today);

        double totalCalories = meals.stream()
                .mapToDouble(meal -> meal.getTotalCalories() == null ? 0 : meal.getTotalCalories())
                .sum();

        double totalProtein = meals.stream()
                .mapToDouble(meal -> meal.getTotalProtein() == null ? 0 : meal.getTotalProtein())
                .sum();

        double totalCarbs = meals.stream()
                .mapToDouble(meal -> meal.getTotalCarbs() == null ? 0 : meal.getTotalCarbs())
                .sum();

        double totalFat = meals.stream()
                .mapToDouble(meal -> meal.getTotalFat() == null ? 0 : meal.getTotalFat())
                .sum();

        double targetCalories = goalCalculatorService.calculateTargetCalories(user);
        double targetProtein = goalCalculatorService.calculateProtein(user);
        double targetCarbs = goalCalculatorService.calculateCarbs(user);
        double targetFat = goalCalculatorService.calculateFat(user);

        List<WorkoutSession> workouts =
                workoutSessionRepository.findByUserAndSessionDateOrderByCreatedAtDesc(user, today);

        String latestWorkoutNote = workouts.isEmpty()
                ? null
                : workouts.getFirst().getNote();

        return DashboardTodayResponse.builder()
                .totalCalories(round(totalCalories))
                .totalProtein(round(totalProtein))
                .totalCarbs(round(totalCarbs))
                .totalFat(round(totalFat))
                .targetCalories(round(targetCalories))
                .targetProtein(round(targetProtein))
                .targetCarbs(round(targetCarbs))
                .targetFat(round(targetFat))
                .caloriesProgressPercent(percent(totalCalories, targetCalories))
                .proteinProgressPercent(percent(totalProtein, targetProtein))
                .carbsProgressPercent(percent(totalCarbs, targetCarbs))
                .fatProgressPercent(percent(totalFat, targetFat))
                .mealCount(meals.size())
                .workoutCount(workouts.size())
                .latestWorkoutNote(latestWorkoutNote)
                .build();
    }

    public DashboardProgressResponse getProgress(User user) {
        List<BodyMeasurement> measurements =
                bodyMeasurementRepository.findByUserOrderByRecordDateAsc(user);

        List<MealLog> meals = mealLogRepository.findByUserOrderByLogDateDesc(user);

        List<WorkoutSession> workouts =
                workoutSessionRepository.findByUserOrderBySessionDateDesc(user);

        Map<LocalDate, Double> caloriesByDate = meals.stream()
                .collect(Collectors.groupingBy(
                        MealLog::getLogDate,
                        Collectors.summingDouble(meal ->
                                meal.getTotalCalories() == null ? 0 : meal.getTotalCalories()
                        )
                ));

        Map<LocalDate, Double> proteinByDate = meals.stream()
                .collect(Collectors.groupingBy(
                        MealLog::getLogDate,
                        Collectors.summingDouble(meal ->
                                meal.getTotalProtein() == null ? 0 : meal.getTotalProtein()
                        )
                ));

        Map<LocalDate, Long> workoutCountByDate = workouts.stream()
                .collect(Collectors.groupingBy(
                        WorkoutSession::getSessionDate,
                        Collectors.counting()
                ));

        List<ProgressPointResponse> points = new ArrayList<>();

        for (BodyMeasurement measurement : measurements) {
            LocalDate date = measurement.getRecordDate();

            points.add(ProgressPointResponse.builder()
                    .date(date)
                    .weight(measurement.getWeight())
                    .waist(measurement.getWaist())
                    .calories(caloriesByDate.getOrDefault(date, 0.0))
                    .protein(proteinByDate.getOrDefault(date, 0.0))
                    .workoutCount(workoutCountByDate.getOrDefault(date, 0L).intValue())
                    .build());
        }

        points.sort(Comparator.comparing(ProgressPointResponse::getDate));

        return DashboardProgressResponse.builder()
                .points(points)
                .build();
    }

    private double percent(double current, double target) {
        if (target <= 0) return 0.0;

        double value = (current / target) * 100;

        return round(Math.min(value, 999));
    }

    private double round(double value) {
        return Math.round(value * 10.0) / 10.0;
    }
}

