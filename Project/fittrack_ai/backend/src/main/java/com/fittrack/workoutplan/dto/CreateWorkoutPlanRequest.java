package com.fittrack.workoutplan.dto;

import lombok.Getter;
import lombok.Setter;

import java.util.List;

@Getter
@Setter
public class CreateWorkoutPlanRequest {
    private String name;
    private String description;
    private Long version;
    private List<CreateWorkoutPlanDayRequest> days;
}

