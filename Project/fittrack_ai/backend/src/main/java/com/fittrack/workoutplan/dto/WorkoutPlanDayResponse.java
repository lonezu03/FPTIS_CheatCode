package com.fittrack.workoutplan.dto;

import lombok.Builder;
import lombok.Getter;

import java.util.List;

@Getter
@Builder
@lombok.NoArgsConstructor
@lombok.AllArgsConstructor
@lombok.Setter
public class WorkoutPlanDayResponse {
    private String id;
    private String name;
    private Integer dayOrder;
    private List<WorkoutPlanExerciseResponse> exercises;
}

