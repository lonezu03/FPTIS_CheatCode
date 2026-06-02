package com.fittrack.demo.dto;

import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class DemoSeedResponse {
    private String message;
    private Integer foodsCreated;
    private Integer exercisesCreated;
    private Integer mealLogsCreated;
    private Integer workoutSessionsCreated;
    private Integer bodyMeasurementsCreated;
}

