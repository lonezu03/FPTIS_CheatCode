package com.fittrack.workoutplan.dto;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class CreateWorkoutPlanExerciseRequest {
    private String exerciseId;
    private Integer exerciseOrder;
    private Integer targetSets;
    private Integer targetReps;
    private Double targetWeight;
    private Integer targetRir;
    private Integer restSeconds;
    private Integer minReps;
    private Integer maxReps;
    private String coachingNote;
    private String groupKey;
    private String groupType;
    private Integer groupRounds;
    private Integer betweenExerciseRestSeconds;
    private Integer betweenRoundRestSeconds;
}

