package com.fittrack.workout.dto;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class CreateWorkoutSetRequest {
    private String exerciseId;
    private Integer setNumber;
    private Double weight;
    private Integer reps;
    private Integer rir;
}