package com.fittrack.workout.controller;

import com.fittrack.user.entity.User;
import com.fittrack.workout.dto.CreateWorkoutSessionRequest;
import com.fittrack.workout.dto.ExerciseResponse;
import com.fittrack.workout.dto.UpdateWorkoutSessionRequest;
import com.fittrack.workout.dto.WorkoutSessionResponse;
import com.fittrack.workout.service.ExerciseService;
import com.fittrack.workout.service.WorkoutService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/workouts")
@RequiredArgsConstructor
public class WorkoutController {

    private final WorkoutService workoutService;
    private final ExerciseService exerciseService;

    @GetMapping("/exercises")
    public List<ExerciseResponse> getExercises() {
        return exerciseService.getExercises(null, false);
    }

    @PostMapping("/sessions")
    public WorkoutSessionResponse createSession(
            Authentication authentication,
            @RequestBody CreateWorkoutSessionRequest request
    ) {
        User user = (User) authentication.getPrincipal();
        return workoutService.createSession(user, request);
    }

    @GetMapping("/sessions")
    public List<WorkoutSessionResponse> getMySessions(Authentication authentication) {
        User user = (User) authentication.getPrincipal();
        return workoutService.getMySessions(user);
    }

    @PutMapping("/sessions/{id}")
    public WorkoutSessionResponse updateSession(
            Authentication authentication,
            @PathVariable String id,
            @RequestBody UpdateWorkoutSessionRequest request
    ) {
        User user = (User) authentication.getPrincipal();

        return workoutService.updateSession(user, id, request);
    }

    @DeleteMapping("/sessions/{id}")
    public void deleteSession(
            Authentication authentication,
            @PathVariable String id
    ) {
        User user = (User) authentication.getPrincipal();

        workoutService.deleteSession(user, id);
    }
}
