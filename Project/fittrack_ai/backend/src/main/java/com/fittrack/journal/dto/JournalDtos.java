package com.fittrack.journal.dto;

import com.fittrack.journal.entity.*;
import jakarta.validation.constraints.*;

import java.time.*;
import java.util.List;

public final class JournalDtos {
    private JournalDtos() {}

    public record PackResponse(String id,String name,String description,String icon,boolean followed,int promptCount) {}
    public record AdminPackResponse(String id, String name, String description, String icon,
                                    boolean active, int sortOrder, int promptCount) {}
    public record AdminPackRequest(@NotBlank @Size(max = 120) String name,
                                   @Size(max = 500) String description,
                                   @Size(max = 20) String icon,
                                   Boolean active,
                                   @Min(0) Integer sortOrder) {}
    public record PromptResponse(String id, String content, JournalCategory category,
                                 JournalDepth depth, boolean active, PackResponse pack) {}

    public record TodayResponse(LocalDate date, PromptResponse prompt, boolean answered,
                                EntryResponse entry) {}

    public record EntryRequest(
            @NotNull JournalOrigin origin,
            String promptId,
            LocalDate entryDate,
            @Size(max = 200) String title,
            @NotBlank @Size(max = 20000) String body,
            JournalMood mood,
            @Size(max=10) List<@Size(max=80) String> tags,
            @Size(max=4) List<@Size(max=2_000_000) String> imageUrls
    ) {
        public EntryRequest(JournalOrigin origin, String promptId, LocalDate entryDate,
                String title, String body, JournalMood mood) {
            this(origin, promptId, entryDate, title, body, mood, null, null);
        }
    }

    public record EntryResponse(
            String id, LocalDate entryDate, JournalOrigin origin, PromptResponse prompt,
            String title, String body, JournalMood mood, List<String> tags, List<String> imageUrls,
            LocalDateTime createdAt, LocalDateTime updatedAt
    ) {}

    public record ReminderSettingsRequest(@NotNull Boolean reminderEnabled, LocalTime reminderTime,
            Boolean personalizedPromptsEnabled, Boolean aiFollowUpEnabled) {
        public ReminderSettingsRequest(Boolean reminderEnabled, LocalTime reminderTime) {
            this(reminderEnabled, reminderTime, null, null);
        }
    }
    public record ReminderSettingsResponse(boolean reminderEnabled, LocalTime reminderTime,
            boolean personalizedPromptsEnabled, boolean aiFollowUpEnabled, boolean lockEnabled) {}

    public record JournalStatsResponse(int writtenDays,int entryCount,List<MoodDayResponse> moodDays) {}
    public record MoodDayResponse(LocalDate date,JournalMood mood) {}
    public record PinRequest(@NotBlank @Pattern(regexp="\\d{4,8}", message="PIN phải gồm 4 đến 8 chữ số") String pin) {}
    public record UnlockResponse(String unlockToken,LocalDateTime expiresAt) {}
    public record AiFollowUpRequest(@NotBlank @Size(max=20000) String body) {}
    public record AiFollowUpResponse(String question) {}

    public record AdminPromptRequest(
            @NotBlank @Size(max = 1000) String content,
            @NotNull JournalCategory category,
            @NotNull JournalDepth depth,
            Boolean active,
            String packId
    ) {
        public AdminPromptRequest(String content, JournalCategory category,
                JournalDepth depth, Boolean active) {
            this(content, category, depth, active, null);
        }
    }
}
