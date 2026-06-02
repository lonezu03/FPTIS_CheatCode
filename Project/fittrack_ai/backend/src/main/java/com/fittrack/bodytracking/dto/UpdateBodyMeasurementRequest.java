package com.fittrack.bodytracking.dto;

import lombok.Getter;
import lombok.Setter;

import java.time.LocalDate;

@Getter
@Setter
public class UpdateBodyMeasurementRequest {
    private Double weight;
    private Double waist;
    private Double chest;
    private Double arm;
    private Double thigh;
    private LocalDate recordDate;
}

