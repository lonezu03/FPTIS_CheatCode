package com.fittrack.report.service;

import com.fittrack.bodytracking.entity.BodyMeasurement;
import com.fittrack.bodytracking.repository.BodyMeasurementRepository;
import com.fittrack.nutrition.entity.MealLog;
import com.fittrack.nutrition.repository.MealLogRepository;
import com.fittrack.report.dto.DailyNutritionSummaryResponse;
import com.fittrack.report.dto.WeeklyReportResponse;
import com.fittrack.user.entity.User;
import com.fittrack.user.service.GoalCalculatorService;
import com.fittrack.workout.entity.WorkoutSession;
import com.fittrack.workout.repository.WorkoutSessionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class WeeklyReportService {

    private final MealLogRepository mealLogRepository;
    private final WorkoutSessionRepository workoutSessionRepository;
    private final BodyMeasurementRepository bodyMeasurementRepository;
    private final GoalCalculatorService goalCalculatorService;

    public WeeklyReportResponse getWeeklyReport(User user, LocalDate fromDate, LocalDate toDate) {
        LocalDate end = toDate == null ? LocalDate.now() : toDate;
        LocalDate start = fromDate == null ? end.minusDays(6) : fromDate;

        List<MealLog> meals =
                mealLogRepository.findByUserAndLogDateBetweenOrderByLogDateAsc(user, start, end);

        List<WorkoutSession> workouts =
                workoutSessionRepository.findByUserAndSessionDateBetweenOrderBySessionDateAsc(user, start, end);

        List<BodyMeasurement> measurements =
                bodyMeasurementRepository.findByUserAndRecordDateBetweenOrderByRecordDateAsc(user, start, end);

        double targetCalories = goalCalculatorService.calculateTargetCalories(user);
        double targetProtein = goalCalculatorService.calculateProtein(user);
        double targetCarbs = goalCalculatorService.calculateCarbs(user);
        double targetFat = goalCalculatorService.calculateFat(user);

        Map<LocalDate, List<MealLog>> mealsByDate = meals.stream()
                .collect(Collectors.groupingBy(MealLog::getLogDate));

        List<DailyNutritionSummaryResponse> dailyNutrition = new ArrayList<>();

        int days = 0;
        double totalCalories = 0;
        double totalProtein = 0;
        double totalCarbs = 0;
        double totalFat = 0;

        LocalDate cursor = start;

        while (!cursor.isAfter(end)) {
            List<MealLog> dayMeals = mealsByDate.getOrDefault(cursor, List.of());

            double dayCalories = dayMeals.stream()
                    .mapToDouble(meal -> meal.getTotalCalories() == null ? 0 : meal.getTotalCalories())
                    .sum();

            double dayProtein = dayMeals.stream()
                    .mapToDouble(meal -> meal.getTotalProtein() == null ? 0 : meal.getTotalProtein())
                    .sum();

            double dayCarbs = dayMeals.stream()
                    .mapToDouble(meal -> meal.getTotalCarbs() == null ? 0 : meal.getTotalCarbs())
                    .sum();

            double dayFat = dayMeals.stream()
                    .mapToDouble(meal -> meal.getTotalFat() == null ? 0 : meal.getTotalFat())
                    .sum();

            totalCalories += dayCalories;
            totalProtein += dayProtein;
            totalCarbs += dayCarbs;
            totalFat += dayFat;

            dailyNutrition.add(DailyNutritionSummaryResponse.builder()
                    .date(cursor)
                    .calories(round(dayCalories))
                    .protein(round(dayProtein))
                    .carbs(round(dayCarbs))
                    .fat(round(dayFat))
                    .targetCalories(round(targetCalories))
                    .targetProtein(round(targetProtein))
                    .caloriesCompliancePercent(percent(dayCalories, targetCalories))
                    .proteinCompliancePercent(percent(dayProtein, targetProtein))
                    .build());

            days++;
            cursor = cursor.plusDays(1);
        }

        double averageCalories = days == 0 ? 0 : totalCalories / days;
        double averageProtein = days == 0 ? 0 : totalProtein / days;
        double averageCarbs = days == 0 ? 0 : totalCarbs / days;
        double averageFat = days == 0 ? 0 : totalFat / days;

        Set<LocalDate> workoutDays = workouts.stream()
                .map(WorkoutSession::getSessionDate)
                .collect(Collectors.toSet());

        Double startWeight = null;
        Double endWeight = null;
        Double weightChange = null;

        Double startWaist = null;
        Double endWaist = null;
        Double waistChange = null;

        if (!measurements.isEmpty()) {
            BodyMeasurement first = measurements.getFirst();
            BodyMeasurement last = measurements.getLast();

            startWeight = first.getWeight();
            endWeight = last.getWeight();

            startWaist = first.getWaist();
            endWaist = last.getWaist();

            if (startWeight != null && endWeight != null) {
                weightChange = endWeight - startWeight;
            }

            if (startWaist != null && endWaist != null) {
                waistChange = endWaist - startWaist;
            }
        }

        double caloriesCompliance = percent(averageCalories, targetCalories);
        double proteinCompliance = percent(averageProtein, targetProtein);

        List<String> insights = buildInsights(
                averageCalories,
                averageProtein,
                targetCalories,
                targetProtein,
                workoutDays.size(),
                weightChange,
                waistChange
        );

        return WeeklyReportResponse.builder()
                .fromDate(start)
                .toDate(end)

                .averageCalories(round(averageCalories))
                .averageProtein(round(averageProtein))
                .averageCarbs(round(averageCarbs))
                .averageFat(round(averageFat))

                .targetCalories(round(targetCalories))
                .targetProtein(round(targetProtein))
                .targetCarbs(round(targetCarbs))
                .targetFat(round(targetFat))

                .totalMeals(meals.size())
                .totalWorkouts(workouts.size())
                .workoutDays(workoutDays.size())

                .startWeight(roundNullable(startWeight))
                .endWeight(roundNullable(endWeight))
                .weightChange(roundNullable(weightChange))

                .startWaist(roundNullable(startWaist))
                .endWaist(roundNullable(endWaist))
                .waistChange(roundNullable(waistChange))

                .caloriesCompliancePercent(caloriesCompliance)
                .proteinCompliancePercent(proteinCompliance)

                .insights(insights)
                .dailyNutrition(dailyNutrition)
                .build();
    }

    private List<String> buildInsights(
            double averageCalories,
            double averageProtein,
            double targetCalories,
            double targetProtein,
            int workoutDays,
            Double weightChange,
            Double waistChange
    ) {
        List<String> insights = new ArrayList<>();

        if (averageCalories < targetCalories * 0.85) {
            insights.add("Calories are quite below target. Consider adding more carbs or healthy fats.");
        } else if (averageCalories > targetCalories * 1.1) {
            insights.add("Calories are above target. Review snacks, drinks, and portion sizes.");
        } else {
            insights.add("Calories are close to your weekly target.");
        }

        if (averageProtein < targetProtein * 0.85) {
            insights.add("Protein intake is below target. Add more lean protein such as chicken breast, eggs, yogurt, or fish.");
        } else {
            insights.add("Protein intake is solid this week.");
        }

        if (workoutDays < 3) {
            insights.add("Workout frequency is low. Aim for at least 3 training days per week.");
        } else {
            insights.add("Workout consistency is good this week.");
        }

        if (weightChange != null) {
            if (weightChange > 0.7) {
                insights.add("Weight increased quickly. If your goal is lean bulk, monitor waist changes.");
            } else if (weightChange < -0.7) {
                insights.add("Weight dropped quickly. Make sure recovery and protein are sufficient.");
            } else {
                insights.add("Weight change is within a controlled weekly range.");
            }
        }

        if (waistChange != null && waistChange > 1.0) {
            insights.add("Waist increased noticeably. Consider lowering calories slightly or increasing activity.");
        }

        return insights;
    }

    private double percent(double current, double target) {
        if (target <= 0) return 0.0;

        return round(Math.min((current / target) * 100, 999));
    }

    private double round(double value) {
        return Math.round(value * 10.0) / 10.0;
    }

    private Double roundNullable(Double value) {
        if (value == null) return null;

        return round(value);
    }
}

