package com.fittrack.notification.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

public final class NotificationPlaybookDtos {
    private NotificationPlaybookDtos() {
    }

    public enum Category {
        WELLNESS,
        MEAL,
        SLEEP,
        PRODUCTIVITY
    }

    public enum Mode {
        FIXED,
        RANDOM
    }

    public enum ConditionType {
        ANY,
        MEALS_LT,
        PROTEIN_GT,
        NO_MEAL
    }

    public enum RecipientMode {
        ALL_ACTIVE,
        SELECTED
    }

    public record PlaybookRequest(
            @NotBlank @Size(max = 180) String name,
            @NotNull Category category,
            @NotNull Mode mode,
            @NotBlank String triggerTime,
            @NotBlank String daysOfWeek,
            @NotBlank String messages,
            @NotNull ConditionType conditionType,
            BigDecimal threshold,
            @NotNull RecipientMode recipientMode,
            List<String> recipientUserIds,
            boolean enabled
    ) {
    }

    public record PlaybookResponse(
            String id,
            String name,
            Category category,
            Mode mode,
            String triggerTime,
            String daysOfWeek,
            String messages,
            ConditionType conditionType,
            BigDecimal threshold,
            RecipientMode recipientMode,
            List<String> recipientUserIds,
            boolean enabled,
            LocalDate lastTriggeredDate,
            LocalDateTime createdAt
    ) {
    }
}
