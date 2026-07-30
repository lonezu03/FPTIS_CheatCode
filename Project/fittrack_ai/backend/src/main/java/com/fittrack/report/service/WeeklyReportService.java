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
            insights.add("Năng lượng nạp vào đang thấp hơn nhiều so với mục tiêu. Hãy cân nhắc bổ sung tinh bột hoặc chất béo lành mạnh.");
        } else if (averageCalories > targetCalories * 1.1) {
            insights.add("Năng lượng nạp vào đang cao hơn mục tiêu. Hãy kiểm tra lại đồ ăn vặt, thức uống và khẩu phần.");
        } else {
            insights.add("Năng lượng trung bình đang gần với mục tiêu của bạn.");
        }

        if (averageProtein < targetProtein * 0.85) {
            insights.add("Lượng protein đang thấp hơn mục tiêu. Hãy bổ sung nguồn đạm nạc như ức gà, trứng, sữa chua hoặc cá.");
        } else {
            insights.add("Lượng protein trong tuần đang ở mức tốt.");
        }

        if (workoutDays < 3) {
            insights.add("Tần suất tập luyện còn thấp. Hãy đặt mục tiêu tập ít nhất 3 ngày mỗi tuần.");
        } else {
            insights.add("Bạn duy trì tập luyện khá đều đặn trong tuần.");
        }

        if (weightChange != null) {
            if (weightChange > 0.7) {
                insights.add("Cân nặng tăng khá nhanh. Nếu đang tăng cơ, hãy theo dõi thêm thay đổi vòng eo.");
            } else if (weightChange < -0.7) {
                insights.add("Cân nặng giảm khá nhanh. Hãy bảo đảm phục hồi và bổ sung đủ protein.");
            } else {
                insights.add("Mức thay đổi cân nặng đang nằm trong khoảng kiểm soát hợp lý.");
            }
        }

        if (waistChange != null && waistChange > 1.0) {
            insights.add("Vòng eo tăng đáng kể. Hãy cân nhắc giảm nhẹ năng lượng nạp vào hoặc tăng vận động.");
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

