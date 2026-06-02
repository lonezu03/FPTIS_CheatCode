package com.fittrack.dashboard.dto;

import lombok.Builder;
import lombok.Getter;

import java.time.LocalDate;

@Getter
@Builder
public class ProgressPointResponse {
    private LocalDate date;
    private Double weight;
    private Double waist;
    private Double calories;
    private Double protein;
    private Integer workoutCount;
}

