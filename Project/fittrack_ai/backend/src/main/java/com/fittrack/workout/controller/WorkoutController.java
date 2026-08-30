package com.fittrack.workout.controller;

import com.fittrack.user.entity.User;
import com.fittrack.workout.dto.CreateWorkoutSessionRequest;
import com.fittrack.workout.dto.ExerciseResponse;
import com.fittrack.workout.dto.UpdateWorkoutSessionRequest;
import com.fittrack.workout.dto.WorkoutSessionResponse;
import com.fittrack.workout.dto.PreviousWorkoutPerformanceResponse;
import com.fittrack.workout.service.ExerciseService;
import com.fittrack.workout.service.WorkoutService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import com.fittrack.common.dto.PageResponse;
import org.springframework.http.ResponseEntity;

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
            @Valid @RequestBody CreateWorkoutSessionRequest request
    ) {
        User user = (User) authentication.getPrincipal();
        return workoutService.createSession(user, request);
    }

    @GetMapping("/sessions")
    public List<WorkoutSessionResponse> getMySessions(Authentication authentication) {
        User user = (User) authentication.getPrincipal();
        return workoutService.getMySessions(user);
    }

    @GetMapping("/sessions/page")
    public PageResponse<WorkoutSessionResponse> getSessionsPage(
            Authentication authentication,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size
    ) {
        return workoutService.getMySessionsPage(
                (User) authentication.getPrincipal(), page, size
        );
    }

    @GetMapping("/previous-performance")
    public ResponseEntity<PreviousWorkoutPerformanceResponse> getPreviousPerformance(
            Authentication authentication,
            @RequestParam String exerciseId
    ) {
        return ResponseEntity.of(workoutService.getPreviousPerformance(
                (User) authentication.getPrincipal(),
                exerciseId
        ));
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
