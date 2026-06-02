package com.fittrack.recommendation.service;

import com.fittrack.recommendation.dto.RecommendationItemResponse;
import com.fittrack.recommendation.dto.WeeklyRecommendationResponse;
import com.fittrack.report.dto.WeeklyReportResponse;
import com.fittrack.report.service.WeeklyReportService;
import com.fittrack.user.entity.User;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
public class RecommendationService {

    private final WeeklyReportService weeklyReportService;

    public WeeklyRecommendationResponse getWeeklyRecommendations(User user, LocalDate fromDate, LocalDate toDate) {
        WeeklyReportResponse report = weeklyReportService.getWeeklyReport(user, fromDate, toDate);

        List<RecommendationItemResponse> items = new ArrayList<>();

        analyzeCalories(report, items);
        analyzeProtein(report, items);
        analyzeWorkout(report, items);
        analyzeWeightAndWaist(report, items);

        if (items.isEmpty()) {
            items.add(RecommendationItemResponse.builder()
                    .type("GENERAL")
                    .severity("LOW")
                    .title("Good week overall")
                    .message("Your nutrition and training look balanced this week.")
                    .action("Keep the same plan next week and continue tracking consistently.")
                    .build());
        }

        return WeeklyRecommendationResponse.builder()
                .fromDate(report.getFromDate())
                .toDate(report.getToDate())
                .summary(buildSummary(report))
                .recommendations(items)
                .build();
    }

    private void analyzeCalories(WeeklyReportResponse report, List<RecommendationItemResponse> items) {
        double avg = safe(report.getAverageCalories());
        double target = safe(report.getTargetCalories());

        if (target <= 0) {
            return;
        }

        double diff = avg - target;

        if (avg < target * 0.85) {
            items.add(RecommendationItemResponse.builder()
                    .type("NUTRITION")
                    .severity("HIGH")
                    .title("Calories are too low")
                    .message("Your average calories are significantly below target.")
                    .action("Increase around " + round(Math.abs(diff)) + " kcal/day. Add rice, sweet potato, milk, olive oil, or larger meal portions.")
                    .build());
        } else if (avg > target * 1.10) {
            items.add(RecommendationItemResponse.builder()
                    .type("NUTRITION")
                    .severity("MEDIUM")
                    .title("Calories are above target")
                    .message("Your average calories are higher than your current goal.")
                    .action("Reduce around " + round(diff) + " kcal/day. Start by cutting snacks, sugary drinks, or excess cooking oil.")
                    .build());
        } else {
            items.add(RecommendationItemResponse.builder()
                    .type("NUTRITION")
                    .severity("LOW")
                    .title("Calories are on track")
                    .message("Your average calories are close to your target.")
                    .action("Keep your current meal structure next week.")
                    .build());
        }
    }

    private void analyzeProtein(WeeklyReportResponse report, List<RecommendationItemResponse> items) {
        double avg = safe(report.getAverageProtein());
        double target = safe(report.getTargetProtein());

        if (target <= 0) {
            return;
        }

        double missing = target - avg;

        if (avg < target * 0.85) {
            items.add(RecommendationItemResponse.builder()
                    .type("PROTEIN")
                    .severity("HIGH")
                    .title("Protein is too low")
                    .message("Your average protein intake is below your target.")
                    .action("Add around " + round(missing) + "g protein/day. Example: chicken breast, eggs, Greek yogurt, or whey.")
                    .build());
        } else if (avg < target) {
            items.add(RecommendationItemResponse.builder()
                    .type("PROTEIN")
                    .severity("MEDIUM")
                    .title("Protein is slightly low")
                    .message("You are close to your protein target but still under it.")
                    .action("Add one small protein serving per day, such as eggs, yogurt, or chicken.")
                    .build());
        } else {
            items.add(RecommendationItemResponse.builder()
                    .type("PROTEIN")
                    .severity("LOW")
                    .title("Protein target reached")
                    .message("Your protein intake is strong this week.")
                    .action("Keep protein stable and adjust calories through carbs/fats if needed.")
                    .build());
        }
    }

    private void analyzeWorkout(WeeklyReportResponse report, List<RecommendationItemResponse> items) {
        int workoutDays = safeInt(report.getWorkoutDays());

        if (workoutDays < 3) {
            items.add(RecommendationItemResponse.builder()
                    .type("TRAINING")
                    .severity("HIGH")
                    .title("Workout frequency is low")
                    .message("You trained fewer than 3 days this week.")
                    .action("Aim for at least 3 sessions next week: Push, Pull, Legs or Full Body 3x/week.")
                    .build());
        } else if (workoutDays <= 4) {
            items.add(RecommendationItemResponse.builder()
                    .type("TRAINING")
                    .severity("LOW")
                    .title("Workout frequency is good")
                    .message("You trained enough days for steady progress.")
                    .action("Focus on progressive overload: add reps, sets, or small weight increases.")
                    .build());
        } else {
            items.add(RecommendationItemResponse.builder()
                    .type("TRAINING")
                    .severity("MEDIUM")
                    .title("High workout frequency")
                    .message("You trained many days this week.")
                    .action("Make sure sleep, calories, and recovery are sufficient. Avoid pushing every set to failure.")
                    .build());
        }
    }

    private void analyzeWeightAndWaist(WeeklyReportResponse report, List<RecommendationItemResponse> items) {
        Double weightChange = report.getWeightChange();
        Double waistChange = report.getWaistChange();

        if (weightChange == null && waistChange == null) {
            items.add(RecommendationItemResponse.builder()
                    .type("BODY")
                    .severity("MEDIUM")
                    .title("Body tracking is missing")
                    .message("There is not enough weight or waist data this week.")
                    .action("Log body weight and waist at least 2 times per week to evaluate progress.")
                    .build());
            return;
        }

        if (weightChange != null && waistChange != null) {
            if (weightChange > 0.7 && waistChange > 1.0) {
                items.add(RecommendationItemResponse.builder()
                        .type("BODY")
                        .severity("HIGH")
                        .title("Bulk may be too aggressive")
                        .message("Weight and waist both increased quickly.")
                        .action("Reduce calories by 150-250 kcal/day or increase daily steps.")
                        .build());
            } else if (weightChange > 0 && waistChange <= 0.5) {
                items.add(RecommendationItemResponse.builder()
                        .type("BODY")
                        .severity("LOW")
                        .title("Lean bulk looks controlled")
                        .message("Weight increased while waist stayed controlled.")
                        .action("Keep calories similar and continue progressive overload.")
                        .build());
            } else if (weightChange < -0.7) {
                items.add(RecommendationItemResponse.builder()
                        .type("BODY")
                        .severity("MEDIUM")
                        .title("Weight dropped quickly")
                        .message("Fast weight loss may affect recovery and strength.")
                        .action("Increase calories slightly or ensure protein and sleep are sufficient.")
                        .build());
            }
        }
    }

    private String buildSummary(WeeklyReportResponse report) {
        return "This week you averaged "
                + round(safe(report.getAverageCalories())) + " kcal/day, "
                + round(safe(report.getAverageProtein())) + "g protein/day, trained "
                + safeInt(report.getWorkoutDays()) + " days, with weight change "
                + formatNullable(report.getWeightChange()) + " kg.";
    }

    private String formatNullable(Double value) {
        if (value == null) {
            return "N/A";
        }

        return String.valueOf(round(value));
    }

    private double safe(Double value) {
        return value == null ? 0.0 : value;
    }

    private int safeInt(Integer value) {
        return value == null ? 0 : value;
    }

    private double round(double value) {
        return Math.round(value * 10.0) / 10.0;
    }
}
