package com.fittrack.workout.dto;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class UpdateExerciseRequest {
    private String name;
    private String muscleGroup;
    private String equipment;
    private String description;
}

