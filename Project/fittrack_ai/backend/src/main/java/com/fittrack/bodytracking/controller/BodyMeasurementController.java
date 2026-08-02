package com.fittrack.bodytracking.controller;

import com.fittrack.bodytracking.dto.BodyMeasurementResponse;
import com.fittrack.bodytracking.dto.CreateBodyMeasurementRequest;
import com.fittrack.bodytracking.dto.UpdateBodyMeasurementRequest;
import com.fittrack.bodytracking.service.BodyMeasurementService;
import com.fittrack.user.entity.User;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import com.fittrack.common.dto.PageResponse;

@RestController
@RequestMapping("/api/body-measurements")
@RequiredArgsConstructor
public class BodyMeasurementController {

    private final BodyMeasurementService service;

    @PostMapping
    public BodyMeasurementResponse create(
            Authentication authentication,
            @RequestBody CreateBodyMeasurementRequest request
    ) {
        User user = (User) authentication.getPrincipal();

        return service.create(user, request);
    }

    @GetMapping
    public List<BodyMeasurementResponse> getMyMeasurements(Authentication authentication) {
        User user = (User) authentication.getPrincipal();

        return service.getMyMeasurements(user);
    }

    @GetMapping("/page")
    public PageResponse<BodyMeasurementResponse> getMyMeasurementsPage(
            Authentication authentication,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size
    ) {
        return service.getMyMeasurementsPage(
                (User) authentication.getPrincipal(), page, size
        );
    }

    @PutMapping("/{id}")
    public BodyMeasurementResponse update(
            Authentication authentication,
            @PathVariable String id,
            @RequestBody UpdateBodyMeasurementRequest request
    ) {
        User user = (User) authentication.getPrincipal();

        return service.update(user, id, request);
    }

    @DeleteMapping("/{id}")
    public void delete(
            Authentication authentication,
            @PathVariable String id
    ) {
        User user = (User) authentication.getPrincipal();

        service.delete(user, id);
    }
}

