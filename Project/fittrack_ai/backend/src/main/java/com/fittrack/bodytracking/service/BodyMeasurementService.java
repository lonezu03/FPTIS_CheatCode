package com.fittrack.bodytracking.service;

import com.fittrack.bodytracking.dto.BodyMeasurementResponse;
import com.fittrack.bodytracking.dto.CreateBodyMeasurementRequest;
import com.fittrack.bodytracking.dto.UpdateBodyMeasurementRequest;
import com.fittrack.bodytracking.entity.BodyMeasurement;
import com.fittrack.bodytracking.mapper.BodyMeasurementMapper;
import com.fittrack.bodytracking.repository.BodyMeasurementRepository;
import com.fittrack.user.entity.User;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class BodyMeasurementService {

    private final BodyMeasurementRepository repository;
    private final BodyMeasurementMapper mapper;

    public BodyMeasurementResponse create(User user, CreateBodyMeasurementRequest request) {
        BodyMeasurement measurement = BodyMeasurement.builder()
                .user(user)
                .weight(request.getWeight())
                .waist(request.getWaist())
                .chest(request.getChest())
                .arm(request.getArm())
                .thigh(request.getThigh())
                .recordDate(request.getRecordDate())
                .build();

        BodyMeasurement saved = repository.save(measurement);

        return mapper.toResponse(saved);
    }

    public List<BodyMeasurementResponse> getMyMeasurements(User user) {
        return mapper.toResponseList(repository.findByUserOrderByRecordDateDesc(user));
    }

    public void delete(User user, String id) {
        BodyMeasurement measurement = repository.findByIdAndUser(id, user)
                .orElseThrow(() -> new IllegalArgumentException("Body measurement not found"));

        repository.delete(measurement);
    }

    public BodyMeasurementResponse update(
            User user,
            String id,
            UpdateBodyMeasurementRequest request
    ) {
        BodyMeasurement measurement = repository.findByIdAndUser(id, user)
                .orElseThrow(() -> new IllegalArgumentException("Body measurement not found"));

        measurement.setWeight(request.getWeight());
        measurement.setWaist(request.getWaist());
        measurement.setChest(request.getChest());
        measurement.setArm(request.getArm());
        measurement.setThigh(request.getThigh());
        measurement.setRecordDate(request.getRecordDate());

        BodyMeasurement saved = repository.save(measurement);

        return mapper.toResponse(saved);
    }
}

