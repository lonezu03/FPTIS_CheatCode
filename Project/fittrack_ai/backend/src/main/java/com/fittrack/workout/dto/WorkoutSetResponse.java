package com.fittrack.workout.dto;

import lombok.Builder;
import lombok.Getter;
import com.fittrack.workout.entity.WorkoutSetType;

@Getter
@Builder
public class WorkoutSetResponse {
    private String originalExerciseId;
    private String replacementKind;
    private String id;
    private String exerciseId;
    private String exerciseName;
    private String muscleGroup;
    private Integer setNumber;
    private String groupKey;
    private String groupType;
    private Integer groupRounds;
    private Integer betweenExerciseRestSeconds;
    private Integer betweenRoundRestSeconds;
    private Integer exerciseOrder;
    private WorkoutSetType setType;
    private Double weight;
    private Integer reps;
    private Integer rir;
    private Integer restSeconds;
    private Boolean completed;
}
