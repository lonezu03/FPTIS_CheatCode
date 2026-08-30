package com.fittrack.health.service;

import com.fittrack.bodytracking.entity.BodyMeasurement;
import com.fittrack.bodytracking.repository.BodyMeasurementRepository;
import com.fittrack.health.dto.HealthDtos.HealthSummaryResponse;
import com.fittrack.health.dto.HealthDtos.HealthScoreBreakdown;
import com.fittrack.health.dto.HealthDtos.NutrientMetric;
import com.fittrack.nutrition.entity.MealItem;
import com.fittrack.nutrition.entity.MealLog;
import com.fittrack.nutrition.repository.MealLogRepository;
import com.fittrack.nutrition.repository.WaterLogRepository;
import com.fittrack.nutrition.entity.NutritionDayStatus;
import com.fittrack.nutrition.entity.WaterLog;
import com.fittrack.nutrition.service.NutritionDayQualityService;
import com.fittrack.user.entity.User;
import com.fittrack.user.service.GoalCalculatorService;
import com.fittrack.workout.entity.WorkoutSession;
import com.fittrack.workout.repository.WorkoutSessionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class HealthSummaryService {

    private final MealLogRepository mealLogRepository;
    private final BodyMeasurementRepository bodyMeasurementRepository;
    private final WorkoutSessionRepository workoutSessionRepository;
    private final GoalCalculatorService goalCalculatorService;
    private final NutritionDayQualityService dayQualityService;
    private final WaterLogRepository waterLogRepository;

    @Transactional(readOnly = true)
    public HealthSummaryResponse summarize(User user, int requestedDays) {
        int days = Math.max(7, Math.min(requestedDays, 365));
        LocalDate to = LocalDate.now();
        LocalDate from = to.minusDays(days - 1L);
        List<MealLog> meals = mealLogRepository
                .findByUserAndLogDateBetweenOrderByLogDateAsc(user, from, to);
        List<WorkoutSession> workouts = workoutSessionRepository
                .findByUserAndSessionDateBetweenOrderBySessionDateAsc(user, from, to);
        List<BodyMeasurement> body = bodyMeasurementRepository
                .findByUserAndRecordDateBetweenOrderByRecordDateAsc(user, from, to);

        int trackedDays = (int) meals.stream()
                .map(MealLog::getLogDate)
                .distinct()
                .count();
        Map<LocalDate, List<MealLog>> mealsByDate = meals.stream()
                .collect(Collectors.groupingBy(MealLog::getLogDate));
        Map<LocalDate, NutritionDayStatus> explicitStatuses =
                dayQualityService.statuses(user, from, to);
        Set<LocalDate> completeDates = new java.util.HashSet<>();
        int partialDays = 0;
        LocalDate cursor = from;
        while (!cursor.isAfter(to)) {
            NutritionDayStatus status = dayQualityService.resolve(
                    cursor, explicitStatuses, mealsByDate
            );
            if (dayQualityService.isComplete(status)) {
                completeDates.add(cursor);
            } else if (status == NutritionDayStatus.PARTIAL) {
                partialDays++;
            }
            cursor = cursor.plusDays(1);
        }
        int completeDays = completeDates.size();
        int unloggedDays = Math.max(0, days - completeDays - partialDays);
        double confidence = round(completeDays * 100.0 / Math.max(1, days));
        List<MealLog> includedMeals = meals.stream()
                .filter(meal -> completeDates.contains(meal.getLogDate()))
                .toList();
        double divisor = Math.max(1, completeDays);
        List<MealItem> mealItems = includedMeals.stream()
                .flatMap(meal -> meal.getItems().stream())
                .toList();
        double targetCalories = goalCalculatorService.calculateTargetCalories(user);
        double macroCoverage = completeDays == 0 ? 0 : 100;
        List<WaterLog> includedWaterLogs = waterLogRepository
                .findByUserAndLoggedAtBetweenOrderByLoggedAtDesc(
                        user, from.atStartOfDay(), to.plusDays(1).atStartOfDay()
                ).stream()
                .filter(log -> completeDates.contains(log.getLoggedAt().toLocalDate()))
                .toList();
        double waterFromLogs = includedWaterLogs.stream()
                .mapToInt(log -> log.getAmountMl())
                .sum();
        double waterCoverage = completeDays == 0 ? 0 : includedWaterLogs.stream()
                .map(log -> log.getLoggedAt().toLocalDate())
                .distinct()
                .count() * 100.0 / completeDays;

        List<NutrientMetric> nutrients = List.of(
                metric("calories", "Năng lượng", sum(includedMeals, MealLog::getTotalCalories) / divisor,
                        targetCalories, "kcal", false, macroCoverage),
                metric("protein", "Chất đạm", sum(includedMeals, MealLog::getTotalProtein) / divisor,
                        goalCalculatorService.calculateProtein(user), "g", false, macroCoverage),
                metric("carbs", "Tinh bột", sum(includedMeals, MealLog::getTotalCarbs) / divisor,
                        goalCalculatorService.calculateCarbs(user), "g", false, macroCoverage),
                metric("fat", "Chất béo", sum(includedMeals, MealLog::getTotalFat) / divisor,
                        goalCalculatorService.calculateFat(user), "g", false, macroCoverage),
                metric("fiber", "Chất xơ", sumItems(mealItems, MealItem::getFiber) / divisor,
                        fiberTarget(user), "g", false, coverage(mealItems, item -> item.getFood().getFiber())),
                metric("sugar", "Đường", sumItems(mealItems, MealItem::getSugar) / divisor,
                        Math.max(25, targetCalories * 0.10 / 4), "g", true, coverage(mealItems, item -> item.getFood().getSugar())),
                metric("sodium", "Natri", sumItems(mealItems, MealItem::getSodium) / divisor,
                        2300, "mg", true, coverage(mealItems, item -> item.getFood().getSodium())),
                metric("potassium", "Kali", sumItems(mealItems, MealItem::getPotassium) / divisor,
                        isFemale(user) ? 2600 : 3400, "mg", false, coverage(mealItems, item -> item.getFood().getPotassium())),
                metric("calcium", "Canxi", sumItems(mealItems, MealItem::getCalcium) / divisor,
                        calciumTarget(user), "mg", false, coverage(mealItems, item -> item.getFood().getCalcium())),
                metric("iron", "Sắt", sumItems(mealItems, MealItem::getIron) / divisor,
                        ironTarget(user), "mg", false, coverage(mealItems, item -> item.getFood().getIron())),
                metric("vitaminC", "Vitamin C", sumItems(mealItems, MealItem::getVitaminC) / divisor,
                        isFemale(user) ? 75 : 90, "mg", false, coverage(mealItems, item -> item.getFood().getVitaminC())),
                metric("water", "Nước", (sumItems(mealItems, MealItem::getWater) + waterFromLogs) / divisor,
                        waterTarget(user), "ml", false, waterCoverage)
        );

        Double currentWeight = body.isEmpty()
                ? user.getWeight()
                : body.get(body.size() - 1).getWeight();
        Double weightChange = body.size() < 2 || body.get(0).getWeight() == null
                || body.get(body.size() - 1).getWeight() == null
                ? null
                : body.get(body.size() - 1).getWeight() - body.get(0).getWeight();
        double bmi = calculateBmi(currentWeight, user.getHeight());
        int activeDays = (int) workouts.stream()
                .map(WorkoutSession::getSessionDate)
                .distinct()
                .count();
        int workoutMinutes = workouts.stream()
                .map(WorkoutSession::getDurationMinutes)
                .filter(value -> value != null && value > 0)
                .mapToInt(Integer::intValue)
                .sum();

        List<String> insights = buildInsights(completeDays, days, activeDays, nutrients, bmi);
        int nutritionScore = (int) Math.round(nutrients.stream()
                .filter(item -> !item.key().equals("sugar") && !item.key().equals("sodium"))
                .filter(item -> item.coveragePercent() >= 80)
                .limit(6)
                .mapToDouble(item -> Math.min(100, item.progressPercent()))
                .average()
                .orElse(0));
        int activityScore = Math.min(100, activeDays * 25);
        int trackingScore = Math.min(100, completeDays * 100 / Math.max(1, days));
        int overallScore = (int) Math.round(
                nutritionScore * 0.55 + activityScore * 0.30 + trackingScore * 0.15
        );

        return new HealthSummaryResponse(
                days,
                trackedDays,
                completeDays,
                partialDays,
                unloggedDays,
                confidence,
                LocalDateTime.now(),
                overallScore,
                confidence < 50,
                new HealthScoreBreakdown(nutritionScore, activityScore, trackingScore),
                round(bmi),
                bmiCategory(bmi),
                currentWeight,
                weightChange == null ? null : round(weightChange),
                meals.size(),
                workouts.size(),
                workoutMinutes,
                activeDays,
                nutrients,
                insights,
                "Mục tiêu được ước tính từ tuổi, giới tính sinh học, cân nặng và mục tiêu năng lượng trong hồ sơ. Chỉ ngày xác nhận ghi đầy đủ mới được dùng để đánh giá.",
                "Các chỉ số chỉ mang tính tham khảo, không thay thế chẩn đoán hoặc tư vấn của nhân viên y tế."
        );
    }

    private double fiberTarget(User user) {
        int age = user.getAge() == null ? 30 : user.getAge();
        if (isFemale(user)) return age > 50 ? 21 : 25;
        return age > 50 ? 30 : 38;
    }

    private double calciumTarget(User user) {
        int age = user.getAge() == null ? 30 : user.getAge();
        return age >= 71 || (isFemale(user) && age >= 51) ? 1200 : 1000;
    }

    private double ironTarget(User user) {
        int age = user.getAge() == null ? 30 : user.getAge();
        return isFemale(user) && age < 51 ? 18 : 8;
    }

    private double waterTarget(User user) {
        double weight = user.getWeight() == null || user.getWeight() <= 0 ? 60 : user.getWeight();
        return Math.max(1500, Math.min(4000, weight * 35));
    }

    private boolean isFemale(User user) {
        return "FEMALE".equalsIgnoreCase(user.getGender());
    }

    private List<String> buildInsights(
            int trackedDays,
            int periodDays,
            int activeDays,
            List<NutrientMetric> nutrients,
            double bmi
    ) {
        List<String> insights = new ArrayList<>();
        if (trackedDays < Math.min(7, periodDays)) {
            insights.add("Hãy ghi nhật ký ăn uống đều đặn hơn để báo cáo chính xác.");
        }
        if (activeDays < 3) {
            insights.add("Bạn nên vận động ít nhất 3 ngày mỗi tuần nếu tình trạng sức khỏe cho phép.");
        }
        nutrients.stream()
                .filter(metric -> metric.coveragePercent() >= 80)
                .filter(metric -> metric.status().equals("LOW"))
                .limit(2)
                .forEach(metric -> insights.add("Lượng " + metric.label().toLowerCase()
                        + " trung bình đang thấp hơn mục tiêu."));
        if (bmi > 0 && (bmi < 18.5 || bmi >= 25)) {
            insights.add("BMI nằm ngoài khoảng tham chiếu phổ biến; nên đánh giá thêm với chuyên gia.");
        }
        if (insights.isEmpty()) {
            insights.add("Các thói quen được ghi nhận đang khá cân bằng. Hãy tiếp tục duy trì.");
        }
        return insights;
    }

    private NutrientMetric metric(
            String key,
            String label,
            double average,
            double target,
            String unit,
            boolean maximum,
            double coveragePercent
    ) {
        double progress = target <= 0 ? 0 : average * 100 / target;
        String status;
        if (coveragePercent <= 0) {
            status = "NO_DATA";
        } else if (coveragePercent < 80) {
            status = "INSUFFICIENT_COVERAGE";
        } else if (target <= 0) {
            status = "NO_TARGET";
        } else if (maximum) {
            status = average > target ? "HIGH" : "GOOD";
        } else if (progress < 70) {
            status = "LOW";
        } else if (progress > 130) {
            status = "HIGH";
        } else {
            status = "GOOD";
        }
        return new NutrientMetric(
                key,
                label,
                round(average),
                round(target),
                unit,
                round(progress),
                status,
                round(coveragePercent)
        );
    }

    private double coverage(
            List<MealItem> items,
            java.util.function.Function<MealItem, Double> getter
    ) {
        if (items.isEmpty()) return 0;
        long available = items.stream().map(getter).filter(java.util.Objects::nonNull).count();
        return available * 100.0 / items.size();
    }

    private double calculateBmi(Double weight, Double heightCm) {
        if (weight == null || heightCm == null || heightCm <= 0) return 0;
        double heightMeters = heightCm / 100;
        return weight / (heightMeters * heightMeters);
    }

    private String bmiCategory(double bmi) {
        if (bmi <= 0) return "Chưa đủ dữ liệu";
        if (bmi < 18.5) return "Thiếu cân";
        if (bmi < 25) return "Bình thường";
        if (bmi < 30) return "Thừa cân";
        return "Béo phì";
    }

    private double sum(List<MealLog> logs, java.util.function.Function<MealLog, Double> getter) {
        return logs.stream().map(getter).mapToDouble(this::safe).sum();
    }

    private double sumItems(List<MealItem> items, java.util.function.Function<MealItem, Double> getter) {
        return items.stream().map(getter).mapToDouble(this::safe).sum();
    }

    private double safe(Double value) {
        return value == null ? 0 : value;
    }

    private double round(double value) {
        return Math.round(value * 10.0) / 10.0;
    }
}
