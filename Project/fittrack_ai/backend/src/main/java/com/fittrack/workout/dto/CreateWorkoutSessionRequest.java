package com.fittrack.workout.dto;

import lombok.Getter;
import lombok.Setter;

import java.time.LocalDate;
import java.util.List;

@Getter
@Setter
public class CreateWorkoutSessionRequest {
    private LocalDate sessionDate;
    private String note;
    private Integer durationMinutes;
    private List<CreateWorkoutSetRequest> sets;
}