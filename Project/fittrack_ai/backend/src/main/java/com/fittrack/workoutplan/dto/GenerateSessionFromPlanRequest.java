package com.fittrack.workoutplan.dto;

import lombok.Getter;
import lombok.Setter;

import java.time.LocalDate;

@Getter
@Setter
public class GenerateSessionFromPlanRequest {
    private String dayId;
    private LocalDate sessionDate;
    private String note;
}

