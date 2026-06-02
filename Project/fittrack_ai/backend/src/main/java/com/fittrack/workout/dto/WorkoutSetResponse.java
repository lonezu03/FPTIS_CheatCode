package com.fittrack.workout.dto;

import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class WorkoutSetResponse {
    private String id;
    private String exerciseId;
    private String exerciseName;
    private String muscleGroup;
    private Integer setNumber;
    private Double weight;
    private Integer reps;
    private Integer rir;
}