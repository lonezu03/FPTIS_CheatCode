package com.fittrack.health.service;

import com.fittrack.bodytracking.entity.BodyMeasurement;
import com.fittrack.bodytracking.repository.BodyMeasurementRepository;
import com.fittrack.health.dto.HealthDtos.HealthSummaryResponse;
import com.fittrack.health.dto.HealthDtos.NutrientMetric;
import com.fittrack.nutrition.entity.MealItem;
import com.fittrack.nutrition.entity.MealLog;
import com.fittrack.nutrition.repository.MealLogRepository;
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

@Service
@RequiredArgsConstructor
public class HealthSummaryService {

    private final MealLogRepository mealLogRepository;
    private final BodyMeasurementRepository bodyMeasurementRepository;
    private final WorkoutSessionRepository workoutSessionRepository;
    private final GoalCalculatorService goalCalculatorService;

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
        double divisor = Math.max(1, trackedDays);
        List<MealItem> mealItems = meals.stream()
                .flatMap(meal -> meal.getItems().stream())
                .toList();
        double targetCalories = goalCalculatorService.calculateTargetCalories(user);

        List<NutrientMetric> nutrients = List.of(
                metric("calories", "Năng lượng", sum(meals, MealLog::getTotalCalories) / divisor,
                        targetCalories, "kcal", false),
                metric("protein", "Chất đạm", sum(meals, MealLog::getTotalProtein) / divisor,
                        goalCalculatorService.calculateProtein(user), "g", false),
                metric("carbs", "Tinh bột", sum(meals, MealLog::getTotalCarbs) / divisor,
                        goalCalculatorService.calculateCarbs(user), "g", false),
                metric("fat", "Chất béo", sum(meals, MealLog::getTotalFat) / divisor,
                        goalCalculatorService.calculateFat(user), "g", false),
                metric("fiber", "Chất xơ", sumItems(mealItems, MealItem::getFiber) / divisor,
                        fiberTarget(user), "g", false),
                metric("sugar", "Đường", sumItems(mealItems, MealItem::getSugar) / divisor,
                        Math.max(25, targetCalories * 0.10 / 4), "g", true),
                metric("sodium", "Natri", sumItems(mealItems, MealItem::getSodium) / divisor,
                        2300, "mg", true),
                metric("potassium", "Kali", sumItems(mealItems, MealItem::getPotassium) / divisor,
                        isFemale(user) ? 2600 : 3400, "mg", false),
                metric("calcium", "Canxi", sumItems(mealItems, MealItem::getCalcium) / divisor,
                        calciumTarget(user), "mg", false),
                metric("iron", "Sắt", sumItems(mealItems, MealItem::getIron) / divisor,
                        ironTarget(user), "mg", false),
                metric("vitaminC", "Vitamin C", sumItems(mealItems, MealItem::getVitaminC) / divisor,
                        isFemale(user) ? 75 : 90, "mg", false),
                metric("water", "Nước", sumItems(mealItems, MealItem::getWater) / divisor,
                        waterTarget(user), "ml", false)
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

        List<String> insights = buildInsights(trackedDays, days, activeDays, nutrients, bmi);
        int nutritionScore = (int) Math.round(nutrients.stream()
                .filter(item -> !item.key().equals("sugar") && !item.key().equals("sodium"))
                .limit(6)
                .mapToDouble(item -> Math.min(100, item.progressPercent()))
                .average()
                .orElse(0));
        int activityScore = Math.min(100, activeDays * 25);
        int trackingScore = Math.min(100, trackedDays * 100 / Math.max(1, days));
        int overallScore = (int) Math.round(
                nutritionScore * 0.55 + activityScore * 0.30 + trackingScore * 0.15
        );

        return new HealthSummaryResponse(
                days,
                trackedDays,
                LocalDateTime.now(),
                overallScore,
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
                "Mục tiêu được ước tính từ tuổi, giới tính sinh học, cân nặng và mục tiêu năng lượng trong hồ sơ.",
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
            boolean maximum
    ) {
        double progress = target <= 0 ? 0 : average * 100 / target;
        String status;
        if (maximum) {
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
                status
        );
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
