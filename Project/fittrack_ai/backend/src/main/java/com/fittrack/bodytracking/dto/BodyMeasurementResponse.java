package com.fittrack.bodytracking.dto;

import lombok.Builder;
import lombok.Getter;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Getter
@Builder
public class BodyMeasurementResponse {
    private String id;
    private Double weight;
    private Double waist;
    private Double chest;
    private Double arm;
    private Double thigh;
    private LocalDate recordDate;
    private LocalDateTime createdAt;
}

