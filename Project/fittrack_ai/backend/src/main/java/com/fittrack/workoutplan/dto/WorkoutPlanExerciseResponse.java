package com.fittrack.workoutplan.dto;

import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class WorkoutPlanExerciseResponse {
    private String id;
    private String exerciseId;
    private String exerciseName;
    private String muscleGroup;
    private Integer exerciseOrder;
    private Integer targetSets;
    private Integer targetReps;
    private Double targetWeight;
    private Integer targetRir;
}

