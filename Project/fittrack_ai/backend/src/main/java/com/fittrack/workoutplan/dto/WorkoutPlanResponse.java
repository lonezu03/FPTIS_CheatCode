package com.fittrack.workoutplan.dto;

import lombok.Builder;
import lombok.Getter;

import java.time.LocalDateTime;
import java.util.List;

@Getter
@Builder
public class WorkoutPlanResponse {
    private String id;
    private String name;
    private String description;
    private LocalDateTime createdAt;
    private List<WorkoutPlanDayResponse> days;
}

