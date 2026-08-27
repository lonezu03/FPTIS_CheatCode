package com.fittrack.todo.dto;

import com.fittrack.todo.entity.Todo;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

import java.time.LocalDateTime;

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
            LocalDateTime dueAt,
            LocalDateTime reminderAt,
            Boolean reminderEnabled
    ) {}

    public record TodoResponse(
            String id,
            String title,
            String description,
            Todo.TodoStatus status,
            Todo.TodoPriority priority,
            LocalDateTime dueAt,
            LocalDateTime reminderAt,
            boolean reminderEnabled,
            LocalDateTime createdAt,
            LocalDateTime updatedAt
    ) {}
}
