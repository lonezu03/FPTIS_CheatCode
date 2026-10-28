package com.fittrack.workoutplan.dto;

import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
@lombok.NoArgsConstructor
@lombok.AllArgsConstructor
@lombok.Setter
public class WorkoutPlanExerciseResponse {
    private String id;
    private String exerciseId;
    private String exerciseName;
    private String muscleGroup;
    private String equipment;
    private String description;
    private String imageUrl;
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

