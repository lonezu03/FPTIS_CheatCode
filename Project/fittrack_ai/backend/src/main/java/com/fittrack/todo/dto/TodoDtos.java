package com.fittrack.todo.dto;

import com.fittrack.todo.entity.Todo;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

import java.time.LocalDateTime;
import java.util.List;

public final class TodoDtos {
    private TodoDtos() {}

    public record TodoRequest(
            @NotBlank(message = "Tên công việc không được để trống")
            @Size(max = 180, message = "Tên công việc tối đa 180 ký tự")
            String title,
            @Size(max = 1000, message = "Mô tả tối đa 1000 ký tự")
            String description,
            Todo.TodoStatus status,
            Todo.TodoPriority priority,
            LocalDateTime startAt,
            LocalDateTime dueAt,
            @Min(value = 1, message = "Thời lượng tối thiểu 1 phút")
            @Max(value = 1_440, message = "Thời lượng tối đa 1.440 phút")
            Integer estimatedMinutes,
            Todo.TodoCategory category,
            Todo.RecurrenceRule recurrenceRule,
            @Min(value = 1, message = "Khoảng lặp tối thiểu là 1")
            @Max(value = 365, message = "Khoảng lặp tối đa là 365")
            Integer recurrenceInterval,
            @Size(max = 100, message = "Danh sách ngày lặp tối đa 100 ký tự")
            String daysOfWeek,
            Todo.RecurrenceBasis recurrenceBasis,
            LocalDateTime recurrenceEndAt,
            @Min(value = 1, message = "Số lần lặp tối thiểu là 1")
            @Max(value = 10_000, message = "Số lần lặp tối đa là 10.000")
            Integer recurrenceMaxOccurrences,
            LocalDateTime reminderAt,
            Boolean reminderEnabled,
            @Size(max = 50, message = "Tối đa 50 checklist")
            List<@Valid SubtaskRequest> subtasks
    ) {
        public TodoRequest(
                String title,
                String description,
                Todo.TodoStatus status,
                Todo.TodoPriority priority,
                LocalDateTime startAt,
                LocalDateTime dueAt,
                Integer estimatedMinutes,
                Todo.TodoCategory category,
                Todo.RecurrenceRule recurrenceRule,
                Integer recurrenceInterval,
                String daysOfWeek,
                LocalDateTime reminderAt,
                Boolean reminderEnabled,
                List<SubtaskRequest> subtasks
        ) {
            this(title, description, status, priority, startAt, dueAt, estimatedMinutes, category,
                    recurrenceRule, recurrenceInterval, daysOfWeek, null, null, null,
                    reminderAt, reminderEnabled, subtasks);
        }

        public TodoRequest(
                String title,
                String description,
                Todo.TodoStatus status,
                Todo.TodoPriority priority,
                LocalDateTime dueAt,
                LocalDateTime reminderAt,
                Boolean reminderEnabled
        ) {
            this(title, description, status, priority, null, dueAt, null, null,
                    null, null, null, null, null, null, reminderAt, reminderEnabled, null);
        }
    }

    public record SubtaskRequest(
            String id,
            @NotBlank(message = "Tên checklist không được để trống")
            @Size(max = 240, message = "Tên checklist tối đa 240 ký tự")
            String title,
            Boolean completed,
            @Min(value = 0, message = "Thứ tự checklist không hợp lệ")
            Integer sortOrder
    ) {}

    public record SubtaskResponse(
            String id,
            String title,
            boolean completed,
            int sortOrder
    ) {}

    public record TodoResponse(
            String id,
            String title,
            String description,
            Todo.TodoStatus status,
            Todo.TodoPriority priority,
            LocalDateTime startAt,
            LocalDateTime dueAt,
            Integer estimatedMinutes,
            Todo.TodoCategory category,
            Todo.RecurrenceRule recurrenceRule,
            Integer recurrenceInterval,
            List<String> daysOfWeek,
            Todo.RecurrenceBasis recurrenceBasis,
            LocalDateTime recurrenceEndAt,
            Integer recurrenceMaxOccurrences,
            Integer occurrenceNumber,
            LocalDateTime completedAt,
            LocalDateTime skippedAt,
            LocalDateTime reminderAt,
            boolean reminderEnabled,
            String recurringSeriesId,
            List<SubtaskResponse> subtasks,
            LocalDateTime createdAt,
            LocalDateTime updatedAt
    ) {}
}
