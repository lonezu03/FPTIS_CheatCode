package com.fittrack.achievement.service;

import com.fittrack.achievement.dto.AchievementResponse;
import com.fittrack.achievement.dto.AchievementSummaryResponse;
import com.fittrack.bodytracking.entity.BodyMeasurement;
import com.fittrack.bodytracking.repository.BodyMeasurementRepository;
import com.fittrack.nutrition.entity.MealLog;
import com.fittrack.nutrition.entity.NutritionDayStatus;
import com.fittrack.nutrition.repository.MealLogRepository;
import com.fittrack.nutrition.service.NutritionDayQualityService;
import com.fittrack.user.entity.User;
import com.fittrack.user.service.GoalCalculatorService;
import com.fittrack.workout.entity.WorkoutSession;
import com.fittrack.workout.repository.WorkoutSessionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class AchievementService {

    private final MealLogRepository mealLogRepository;
    private final WorkoutSessionRepository workoutSessionRepository;
    private final BodyMeasurementRepository bodyMeasurementRepository;
    private final GoalCalculatorService goalCalculatorService;
    private final NutritionDayQualityService dayQualityService;

    public AchievementSummaryResponse getSummary(User user) {
        LocalDate today = LocalDate.now();
        LocalDate weekStart = today.minusDays(6);

        int mealStreak = calculateMealLoggingStreak(user, today);
        int workoutStreak = calculateWorkoutStreak(user, today);
        int proteinHitDays = calculateProteinHitDays(user, weekStart, today);
        int bodyTrackingDays = calculateBodyTrackingDays(user, weekStart, today);
        int workoutDays = calculateWorkoutDays(user, weekStart, today);

        List<AchievementResponse> achievements = List.of(
                achievement(
                        "MEAL_STREAK_3",
                        "Duy trì nhật ký bữa ăn",
                        "Ghi lại bữa ăn trong 3 ngày liên tiếp.",
                        mealStreak,
                        3
                ),
                achievement(
                        "MEAL_STREAK_7",
                        "Kỷ luật dinh dưỡng",
                        "Ghi lại bữa ăn trong 7 ngày liên tiếp.",
                        mealStreak,
                        7
                ),
                achievement(
                        "WORKOUT_3_WEEK",
                        "Tập luyện đều đặn",
                        "Hoàn thành 3 ngày tập trong tuần.",
                        workoutDays,
                        3
                ),
                achievement(
                        "WORKOUT_5_WEEK",
                        "Tuần tập luyện tích cực",
                        "Hoàn thành 5 ngày tập trong tuần.",
                        workoutDays,
                        5
                ),
                achievement(
                        "PROTEIN_5_WEEK",
                        "Đạt mục tiêu protein",
                        "Đạt mục tiêu protein trong 5 ngày của tuần.",
                        proteinHitDays,
                        5
                ),
                achievement(
                        "BODY_TRACK_2_WEEK",
                        "Theo dõi tiến độ cơ thể",
                        "Ghi chỉ số cơ thể trong 2 ngày của tuần.",
                        bodyTrackingDays,
                        2
                )
        );

        return AchievementSummaryResponse.builder()
                .mealLoggingStreak(mealStreak)
                .workoutStreak(workoutStreak)
                .proteinHitDaysThisWeek(proteinHitDays)
                .bodyTrackingDaysThisWeek(bodyTrackingDays)
                .achievements(achievements)
                .build();
    }

    private AchievementResponse achievement(
            String code,
            String title,
            String description,
            int progress,
            int target
    ) {
        return AchievementResponse.builder()
                .code(code)
                .title(title)
                .description(description)
                .progress(Math.min(progress, target))
                .target(target)
                .unlocked(progress >= target)
                .build();
    }

    /** Số ngày nạp mỗi lần khi tính chuỗi, tránh một truy vấn cho từng ngày. */
    private static final int STREAK_WINDOW_DAYS = 60;

    private int calculateMealLoggingStreak(User user, LocalDate today) {
        int streak = 0;
        LocalDate windowEnd = today;

        while (true) {
            LocalDate windowStart = windowEnd.minusDays(STREAK_WINDOW_DAYS - 1);
            Map<LocalDate, List<MealLog>> meals = mealsByDate(user, windowStart, windowEnd);
            Map<LocalDate, NutritionDayStatus> explicit =
                    dayQualityService.statuses(user, windowStart, windowEnd);

            for (LocalDate cursor = windowEnd; !cursor.isBefore(windowStart); cursor = cursor.minusDays(1)) {
                if (!dayQualityService.isComplete(dayQualityService.resolve(cursor, explicit, meals))) {
                    return streak;
                }
                streak++;
            }
            windowEnd = windowStart.minusDays(1);
        }
    }

    private int calculateWorkoutStreak(User user, LocalDate today) {
        int streak = 0;
        LocalDate windowEnd = today;

        while (true) {
            LocalDate windowStart = windowEnd.minusDays(STREAK_WINDOW_DAYS - 1);
            Set<LocalDate> workoutDates = workoutSessionRepository
                    .findByUserAndSessionDateBetweenOrderBySessionDateAsc(user, windowStart, windowEnd)
                    .stream()
                    .map(WorkoutSession::getSessionDate)
                    .collect(Collectors.toSet());

            for (LocalDate cursor = windowEnd; !cursor.isBefore(windowStart); cursor = cursor.minusDays(1)) {
                if (!workoutDates.contains(cursor)) {
                    return streak;
                }
                streak++;
            }
            windowEnd = windowStart.minusDays(1);
        }
    }

    private Map<LocalDate, List<MealLog>> mealsByDate(User user, LocalDate from, LocalDate to) {
        return mealLogRepository.findByUserAndLogDateBetweenOrderByLogDateAsc(user, from, to)
                .stream()
                .collect(Collectors.groupingBy(MealLog::getLogDate));
    }

    private int calculateWorkoutDays(User user, LocalDate fromDate, LocalDate toDate) {
        List<WorkoutSession> sessions =
                workoutSessionRepository.findByUserAndSessionDateBetweenOrderBySessionDateAsc(
                        user,
                        fromDate,
                        toDate
                );

        return (int) sessions.stream()
                .map(WorkoutSession::getSessionDate)
                .distinct()
                .count();
    }

    private int calculateBodyTrackingDays(User user, LocalDate fromDate, LocalDate toDate) {
        List<BodyMeasurement> measurements =
                bodyMeasurementRepository.findByUserAndRecordDateBetweenOrderByRecordDateAsc(
                        user,
                        fromDate,
                        toDate
                );

        return (int) measurements.stream()
                .map(BodyMeasurement::getRecordDate)
                .distinct()
                .count();
    }

    private int calculateProteinHitDays(User user, LocalDate fromDate, LocalDate toDate) {
        double proteinTarget = goalCalculatorService.calculateProtein(user);

        Map<LocalDate, List<MealLog>> meals = mealsByDate(user, fromDate, toDate);
        Map<LocalDate, NutritionDayStatus> explicit = dayQualityService.statuses(user, fromDate, toDate);

        int hitDays = 0;
        for (LocalDate cursor = fromDate; !cursor.isAfter(toDate); cursor = cursor.plusDays(1)) {
            if (!dayQualityService.isComplete(dayQualityService.resolve(cursor, explicit, meals))) {
                continue;
            }

            double protein = meals.getOrDefault(cursor, List.of()).stream()
                    .mapToDouble(log -> log.getTotalProtein() == null ? 0 : log.getTotalProtein())
                    .sum();

            if (protein >= proteinTarget) {
                hitDays++;
            }
        }

        return hitDays;
    }
}

