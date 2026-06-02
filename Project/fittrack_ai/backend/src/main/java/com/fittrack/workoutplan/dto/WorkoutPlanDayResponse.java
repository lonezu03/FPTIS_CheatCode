package com.fittrack.workoutplan.dto;

import lombok.Builder;
import lombok.Getter;

import java.util.List;

@Getter
@Builder
public class WorkoutPlanDayResponse {
    private String id;
    private String name;
    private Integer dayOrder;
    private List<WorkoutPlanExerciseResponse> exercises;
}

