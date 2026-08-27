package com.fittrack.schedule.dto;

import com.fittrack.schedule.entity.ScheduleItem;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.time.LocalDateTime;

public final class ScheduleDtos {
    private ScheduleDtos() {}

    public record ScheduleRequest(
            @NotBlank(message = "Tên hoạt động không được để trống")
            @Size(max = 180, message = "Tên hoạt động tối đa 180 ký tự")
            String title,
            @Size(max = 1000, message = "Mô tả tối đa 1000 ký tự")
            String description,
            ScheduleItem.ScheduleCategory category,
            @NotNull(message = "Vui lòng chọn thời gian bắt đầu")
            LocalDateTime startAt,
            LocalDateTime endAt,
            ScheduleItem.RepeatRule repeatRule,
            @Size(max = 100, message = "Danh sách ngày tối đa 100 ký tự")
            String daysOfWeek,
            @Min(value = 0, message = "Số phút nhắc không được âm")
            Integer reminderMinutes,
            Boolean reminderEnabled,
            Boolean enabled
    ) {}

    public record ScheduleResponse(
            String id,
            String title,
            String description,
            ScheduleItem.ScheduleCategory category,
            LocalDateTime startAt,
            LocalDateTime endAt,
            ScheduleItem.RepeatRule repeatRule,
            String daysOfWeek,
            int reminderMinutes,
            boolean reminderEnabled,
            boolean enabled,
            LocalDateTime lastRemindedAt,
            LocalDateTime createdAt
    ) {}
}
