package com.fittrack.workout.dto;

import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class ExerciseResponse {
    private String id;
    private String name;
    private String muscleGroup;
    private String equipment;
    private String description;
    private Boolean custom;
    private Boolean active;
}