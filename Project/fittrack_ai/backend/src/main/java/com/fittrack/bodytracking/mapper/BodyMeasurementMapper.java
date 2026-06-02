package com.fittrack.bodytracking.mapper;

import com.fittrack.bodytracking.dto.BodyMeasurementResponse;
import com.fittrack.bodytracking.entity.BodyMeasurement;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
public class BodyMeasurementMapper {

    public BodyMeasurementResponse toResponse(BodyMeasurement measurement) {
        return BodyMeasurementResponse.builder()
                .id(measurement.getId())
                .weight(measurement.getWeight())
                .waist(measurement.getWaist())
                .chest(measurement.getChest())
                .arm(measurement.getArm())
                .thigh(measurement.getThigh())
                .recordDate(measurement.getRecordDate())
                .createdAt(measurement.getCreatedAt())
                .build();
    }

    public List<BodyMeasurementResponse> toResponseList(List<BodyMeasurement> measurements) {
        return measurements.stream()
                .map(this::toResponse)
                .toList();
    }
}

