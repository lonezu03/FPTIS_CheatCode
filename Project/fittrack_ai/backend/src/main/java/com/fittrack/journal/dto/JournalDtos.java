package com.fittrack.journal.dto;

import com.fittrack.journal.entity.*;
import jakarta.validation.constraints.*;

import java.time.*;

public final class JournalDtos {
    private JournalDtos() {}

    public record PromptResponse(String id, String content, JournalCategory category,
                                 JournalDepth depth, boolean active) {}

    public record TodayResponse(LocalDate date, PromptResponse prompt, boolean answered,
                                EntryResponse entry) {}

    public record EntryRequest(
            @NotNull JournalOrigin origin,
            String promptId,
            LocalDate entryDate,
            @Size(max = 200) String title,
            @NotBlank @Size(max = 20000) String body,
            JournalMood mood
    ) {}

    public record EntryResponse(
            String id, LocalDate entryDate, JournalOrigin origin, PromptResponse prompt,
            String title, String body, JournalMood mood,
            LocalDateTime createdAt, LocalDateTime updatedAt
    ) {}

    public record ReminderSettingsRequest(@NotNull Boolean reminderEnabled, LocalTime reminderTime) {}
    public record ReminderSettingsResponse(boolean reminderEnabled, LocalTime reminderTime) {}

    public record AdminPromptRequest(
            @NotBlank @Size(max = 1000) String content,
            @NotNull JournalCategory category,
            @NotNull JournalDepth depth,
            Boolean active
    ) {}
}
