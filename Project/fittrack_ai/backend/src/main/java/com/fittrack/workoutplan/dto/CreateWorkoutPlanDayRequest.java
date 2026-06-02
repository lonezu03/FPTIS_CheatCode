package com.fittrack.workoutplan.dto;

import lombok.Getter;
import lombok.Setter;

import java.util.List;

@Getter
@Setter
public class CreateWorkoutPlanDayRequest {
    private String name;
    private Integer dayOrder;
    private List<CreateWorkoutPlanExerciseRequest> exercises;
}

