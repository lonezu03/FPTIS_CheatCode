package com.fittrack.achievement.service;

import com.fittrack.achievement.dto.AchievementResponse;
import com.fittrack.achievement.dto.AchievementSummaryResponse;
import com.fittrack.bodytracking.entity.BodyMeasurement;
import com.fittrack.bodytracking.repository.BodyMeasurementRepository;
import com.fittrack.nutrition.entity.MealLog;
import com.fittrack.nutrition.repository.MealLogRepository;
import com.fittrack.user.entity.User;
import com.fittrack.user.service.GoalCalculatorService;
import com.fittrack.workout.entity.WorkoutSession;
import com.fittrack.workout.repository.WorkoutSessionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.List;

@Service
@RequiredArgsConstructor
public class AchievementService {

    private final MealLogRepository mealLogRepository;
    private final WorkoutSessionRepository workoutSessionRepository;
    private final BodyMeasurementRepository bodyMeasurementRepository;
    private final GoalCalculatorService goalCalculatorService;

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
                        "Meal Logger",
                        "Log meals for 3 days in a row.",
                        mealStreak,
                        3
                ),
                achievement(
                        "MEAL_STREAK_7",
                        "Nutrition Discipline",
                        "Log meals for 7 days in a row.",
                        mealStreak,
                        7
                ),
                achievement(
                        "WORKOUT_3_WEEK",
                        "Consistent Trainee",
                        "Complete 3 workout days this week.",
                        workoutDays,
                        3
                ),
                achievement(
                        "WORKOUT_5_WEEK",
                        "High Volume Week",
                        "Complete 5 workout days this week.",
                        workoutDays,
                        5
                ),
                achievement(
                        "PROTEIN_5_WEEK",
                        "Protein Focused",
                        "Hit protein target 5 days this week.",
                        proteinHitDays,
                        5
                ),
                achievement(
                        "BODY_TRACK_2_WEEK",
                        "Progress Tracker",
                        "Log body measurements 2 days this week.",
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

    private int calculateMealLoggingStreak(User user, LocalDate today) {
        int streak = 0;
        LocalDate cursor = today;

        while (true) {
            List<MealLog> logs = mealLogRepository.findByUserAndLogDate(user, cursor);

            if (logs.isEmpty()) {
                break;
            }

            streak++;
            cursor = cursor.minusDays(1);
        }

        return streak;
    }

    private int calculateWorkoutStreak(User user, LocalDate today) {
        int streak = 0;
        LocalDate cursor = today;

        while (true) {
            List<WorkoutSession> sessions =
                    workoutSessionRepository.findByUserAndSessionDateOrderByCreatedAtDesc(user, cursor);

            if (sessions.isEmpty()) {
                break;
            }

            streak++;
            cursor = cursor.minusDays(1);
        }

        return streak;
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

        int hitDays = 0;
        LocalDate cursor = fromDate;

        while (!cursor.isAfter(toDate)) {
            List<MealLog> logs = mealLogRepository.findByUserAndLogDate(user, cursor);

            double protein = logs.stream()
                    .mapToDouble(log -> log.getTotalProtein() == null ? 0 : log.getTotalProtein())
                    .sum();

            if (protein >= proteinTarget) {
                hitDays++;
            }

            cursor = cursor.plusDays(1);
        }

        return hitDays;
    }
}

