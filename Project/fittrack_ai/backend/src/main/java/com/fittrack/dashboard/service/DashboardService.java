package com.fittrack.dashboard.service;

import com.fittrack.bodytracking.entity.BodyMeasurement;
import com.fittrack.bodytracking.repository.BodyMeasurementRepository;
import com.fittrack.dashboard.dto.DashboardProgressResponse;
import com.fittrack.dashboard.dto.DashboardTodayResponse;
import com.fittrack.dashboard.dto.DashboardAgendaItemResponse;
import com.fittrack.dashboard.dto.ProgressPointResponse;
import com.fittrack.nutrition.entity.MealLog;
import com.fittrack.nutrition.repository.MealLogRepository;
import com.fittrack.user.entity.User;
import com.fittrack.user.service.GoalCalculatorService;
import com.fittrack.workout.entity.WorkoutSession;
import com.fittrack.workout.repository.WorkoutSessionRepository;
import com.fittrack.schedule.service.ScheduleService;
import com.fittrack.schedule.dto.ScheduleDtos.CalendarEntryResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class DashboardService {

    private static final ZoneId BUSINESS_ZONE = ZoneId.of("Asia/Ho_Chi_Minh");

    private final BodyMeasurementRepository bodyMeasurementRepository;
    private final MealLogRepository mealLogRepository;
    private final WorkoutSessionRepository workoutSessionRepository;
    private final GoalCalculatorService goalCalculatorService;
    private final ScheduleService scheduleService;

    public DashboardTodayResponse getTodayDashboard(User user) {
        LocalDate today = LocalDate.now(BUSINESS_ZONE);
        boolean admin = "ADMIN".equalsIgnoreCase(user.getRole());
        boolean canHealth = admin || Boolean.TRUE.equals(user.getHealthEnabled());
        boolean canFitness = admin || Boolean.TRUE.equals(user.getFitnessEnabled());
        boolean canTodo = admin || Boolean.TRUE.equals(user.getTodoEnabled());
        boolean canSchedule = admin || Boolean.TRUE.equals(user.getScheduleEnabled());

        List<MealLog> meals = canHealth
                ? mealLogRepository.findByUserAndLogDate(user, today)
                : List.of();

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

        double targetCalories = canHealth ? goalCalculatorService.calculateTargetCalories(user) : 0;
        double targetProtein = canHealth ? goalCalculatorService.calculateProtein(user) : 0;
        double targetCarbs = canHealth ? goalCalculatorService.calculateCarbs(user) : 0;
        double targetFat = canHealth ? goalCalculatorService.calculateFat(user) : 0;

        List<WorkoutSession> workouts = canFitness
                ? workoutSessionRepository.findByUserAndSessionDateOrderByCreatedAtDesc(user, today)
                : List.of();

        String latestWorkoutNote = workouts.isEmpty()
                ? null
                : workouts.getFirst().getNote();

        List<CalendarEntryResponse> calendar = canTodo || canSchedule
                ? scheduleService.getCalendar(user, today.atStartOfDay(), today.plusDays(1).atStartOfDay())
                : List.of();
        List<DashboardAgendaItemResponse> agenda = calendar.stream()
                .filter(item -> ("TODO".equals(item.sourceType()) && canTodo)
                        || ("EVENT".equals(item.sourceType()) && canSchedule))
                .limit(8)
                .map(item -> DashboardAgendaItemResponse.builder()
                        .sourceType(item.sourceType())
                        .sourceId(item.sourceId())
                        .title(item.title())
                        .category(item.category())
                        .status(item.status())
                        .startAt(item.startAt())
                        .endAt(item.endAt())
                        .build())
                .toList();
        int openTodos = (int) agenda.stream()
                .filter(item -> "TODO".equals(item.getSourceType()))
                .filter(item -> !"DONE".equals(item.getStatus()))
                .count();
        int scheduleCount = (int) agenda.stream()
                .filter(item -> "EVENT".equals(item.getSourceType())).count();
        String coachInsight = canHealth || canFitness || canTodo
                ? coachInsight(
                        user, totalCalories, totalProtein, targetCalories, targetProtein,
                        workouts.size(), openTodos
                )
                : null;
        String coachActionPath = canHealth
                && totalProtein < targetProtein * 0.75 ? "/nutrition"
                : canFitness && workouts.isEmpty()
                ? "/workouts" : openTodos > 0 ? "/todos" : canHealth ? "/reports/weekly" : null;

        return DashboardTodayResponse.builder()
                .date(today)
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
                .lunchEnabled(Boolean.TRUE.equals(user.getLunchEnabled()))
                .fitnessEnabled(Boolean.TRUE.equals(user.getFitnessEnabled()))
                .healthEnabled(Boolean.TRUE.equals(user.getHealthEnabled()))
                .todoEnabled(Boolean.TRUE.equals(user.getTodoEnabled()))
                .scheduleEnabled(Boolean.TRUE.equals(user.getScheduleEnabled()))
                .quoteEnabled(Boolean.TRUE.equals(user.getQuoteEnabled()))
                .latestWorkoutNote(latestWorkoutNote)
                .remainingCalories(round(targetCalories - totalCalories))
                .remainingProtein(round(targetProtein - totalProtein))
                .openTodoCount(openTodos)
                .scheduleCount(scheduleCount)
                .agenda(agenda)
                .coachInsight(coachInsight)
                .coachActionPath(coachActionPath)
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

        Map<LocalDate, BodyMeasurement> measurementByDate = measurements.stream()
                .collect(Collectors.toMap(
                        BodyMeasurement::getRecordDate,
                        measurement -> measurement,
                        (first, latest) -> latest
                ));
        java.util.Set<LocalDate> dates = new java.util.TreeSet<>();
        dates.addAll(measurementByDate.keySet());
        dates.addAll(caloriesByDate.keySet());
        dates.addAll(proteinByDate.keySet());
        dates.addAll(workoutCountByDate.keySet());

        List<ProgressPointResponse> points = new ArrayList<>();
        for (LocalDate date : dates) {
            BodyMeasurement measurement = measurementByDate.get(date);
            points.add(ProgressPointResponse.builder()
                    .date(date)
                    .weight(measurement == null ? null : measurement.getWeight())
                    .waist(measurement == null ? null : measurement.getWaist())
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

    private String coachInsight(
            User user,
            double calories,
            double protein,
            double targetCalories,
            double targetProtein,
            int workouts,
            int openTodos
    ) {
        if (Boolean.TRUE.equals(user.getHealthEnabled()) && protein < targetProtein * 0.75) {
            return "Bạn còn thiếu khoảng " + Math.max(0, Math.round(targetProtein - protein))
                    + " g protein hôm nay. Ưu tiên một nguồn đạm phù hợp trong bữa tiếp theo.";
        }
        if (Boolean.TRUE.equals(user.getHealthEnabled()) && calories > targetCalories * 1.1) {
            return "Năng lượng hôm nay đã vượt mục tiêu. Hãy ghi đầy đủ rồi đánh giá theo xu hướng tuần, không cần bù trừ cực đoan.";
        }
        if (Boolean.TRUE.equals(user.getFitnessEnabled()) && workouts == 0) {
            return "Hôm nay chưa có buổi tập. Bạn có thể mở Workout để xem mức tạ và reps FitTrack đề xuất.";
        }
        if (openTodos > 0) {
            return "Bạn còn " + openTodos + " việc trong lịch hôm nay. Hoàn thành việc quan trọng nhất trước.";
        }
        return "Dữ liệu hôm nay đang ổn. Tiếp tục ghi nhận đều đặn để FitTrack đưa ra hướng dẫn chính xác hơn.";
    }
}

