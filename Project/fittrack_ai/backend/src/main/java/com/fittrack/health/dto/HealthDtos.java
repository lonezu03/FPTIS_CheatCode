package com.fittrack.health.dto;

import jakarta.validation.constraints.*;

import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;
import java.util.Set;

public final class HealthDtos {

    private HealthDtos() {
    }

    public record NutrientMetric(
            String key,
            String label,
            double average,
            double target,
            String unit,
            double progressPercent,
            String status
    ) {
    }

    public record HealthSummaryResponse(
            int periodDays,
            int trackedNutritionDays,
            LocalDateTime generatedAt,
            int overallScore,
            double bmi,
            String bmiCategory,
            Double currentWeight,
            Double weightChange,
            int mealCount,
            int workoutSessions,
            int workoutMinutes,
            int activeDays,
            List<NutrientMetric> nutrients,
            List<String> insights,
            String disclaimer
    ) {
    }

    public record ReminderRequest(
            @NotBlank(message = "Vui lòng chọn loại nhắc nhở")
            @Pattern(
                    regexp = "MEAL|WATER|WORKOUT|MEDICATION|SLEEP|CUSTOM",
                    message = "Loại nhắc nhở không hợp lệ"
            )
            String type,
            @NotBlank(message = "Vui lòng nhập tiêu đề")
            @Size(max = 180, message = "Tiêu đề tối đa 180 ký tự")
            String title,
            @Size(max = 500, message = "Nội dung tối đa 500 ký tự")
            String message,
            @NotNull(message = "Vui lòng chọn giờ nhắc")
            LocalTime reminderTime,
            @NotEmpty(message = "Vui lòng chọn ít nhất một ngày")
            Set<DayOfWeek> daysOfWeek,
            Boolean enabled
    ) {
    }

    public record ReminderResponse(
            String id,
            String type,
            String title,
            String message,
            LocalTime reminderTime,
            Set<DayOfWeek> daysOfWeek,
            boolean enabled,
            LocalDate lastTriggeredDate,
            LocalDateTime createdAt
    ) {
    }
}
