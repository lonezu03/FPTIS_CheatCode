package com.fittrack.workout.dto;

import lombok.Builder;
import lombok.Getter;

import java.time.LocalDate;
import java.util.List;

@Getter
@Builder
public class PreviousWorkoutPerformanceResponse {
    private String exerciseId;
    private String exerciseName;
    private LocalDate sessionDate;
    private List<WorkoutSetResponse> sets;
}
