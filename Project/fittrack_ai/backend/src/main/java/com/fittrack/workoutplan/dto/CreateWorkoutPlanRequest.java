package com.fittrack.workoutplan.dto;

import lombok.Getter;
import lombok.Setter;

import java.util.List;

@Getter
@Setter
public class CreateWorkoutPlanRequest {
    private String name;
    private String description;
    private List<CreateWorkoutPlanDayRequest> days;
}

