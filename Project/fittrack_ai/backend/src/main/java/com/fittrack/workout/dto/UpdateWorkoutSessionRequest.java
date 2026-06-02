package com.fittrack.workout.dto;

import lombok.Getter;
import lombok.Setter;

import java.time.LocalDate;

@Getter
@Setter
public class UpdateWorkoutSessionRequest {
    private LocalDate sessionDate;
    private String note;
    private Integer durationMinutes;
    private Double weight;
    private Integer reps;
    private Integer rir;
}

