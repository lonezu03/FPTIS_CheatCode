package com.fittrack.workout.dto;

import lombok.Builder;
import lombok.Getter;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

import com.fittrack.workout.dto.WorkoutIntelligenceDtos.NewPersonalRecordResponse;

@Getter
@Builder
public class WorkoutSessionResponse {
    private String id;
    private LocalDate sessionDate;
    private String note;
    private Integer durationMinutes;
    private LocalDateTime createdAt;
    private List<WorkoutSetResponse> sets;
    @Builder.Default
    private List<NewPersonalRecordResponse> newPersonalRecords = List.of();
}

