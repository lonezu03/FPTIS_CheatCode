package com.fittrack.workoutplan.controller;

import com.fittrack.user.entity.User;
import com.fittrack.workout.dto.WorkoutSessionResponse;
import com.fittrack.workoutplan.dto.CreateWorkoutPlanRequest;
import com.fittrack.workoutplan.dto.GenerateSessionFromPlanRequest;
import com.fittrack.workoutplan.dto.WorkoutPlanResponse;
import com.fittrack.workoutplan.service.WorkoutPlanService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/workout-plans")
@RequiredArgsConstructor
public class WorkoutPlanController {

    private final WorkoutPlanService workoutPlanService;

    @PostMapping
    public WorkoutPlanResponse createPlan(
            Authentication authentication,
            @RequestBody CreateWorkoutPlanRequest request
    ) {
        User user = (User) authentication.getPrincipal();

        return workoutPlanService.createPlan(user, request);
    }

    @GetMapping
    public List<WorkoutPlanResponse> getMyPlans(Authentication authentication) {
        User user = (User) authentication.getPrincipal();

        return workoutPlanService.getMyPlans(user);
    }

    @GetMapping("/{id}")
    public WorkoutPlanResponse getPlanDetail(
            Authentication authentication,
            @PathVariable String id
    ) {
        User user = (User) authentication.getPrincipal();

        return workoutPlanService.getPlanDetail(user, id);
    }

    @DeleteMapping("/{id}")
    public void deletePlan(
            Authentication authentication,
            @PathVariable String id
    ) {
        User user = (User) authentication.getPrincipal();

        workoutPlanService.deletePlan(user, id);
    }

    @PostMapping("/{id}/generate-session")
    public WorkoutSessionResponse generateSession(
            Authentication authentication,
            @PathVariable String id,
            @RequestBody GenerateSessionFromPlanRequest request
    ) {
        User user = (User) authentication.getPrincipal();

        return workoutPlanService.generateSessionFromPlan(user, id, request);
    }
}

