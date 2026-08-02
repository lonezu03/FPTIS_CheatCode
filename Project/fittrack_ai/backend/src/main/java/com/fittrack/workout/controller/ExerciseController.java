package com.fittrack.workout.controller;

import com.fittrack.workout.dto.CreateExerciseRequest;
import com.fittrack.workout.dto.ExerciseResponse;
import com.fittrack.workout.dto.UpdateExerciseRequest;
import com.fittrack.workout.service.ExerciseService;
import com.fittrack.common.dto.CatalogReviewRequest;
import com.fittrack.user.entity.User;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;
import org.springframework.security.core.annotation.AuthenticationPrincipal;

import java.util.List;
import com.fittrack.common.dto.PageResponse;

@RestController
@RequestMapping("/api/exercises")
@RequiredArgsConstructor
public class ExerciseController {

    private final ExerciseService exerciseService;

    @GetMapping
    public List<ExerciseResponse> getExercises(
            @AuthenticationPrincipal User user,
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) Boolean includeInactive
    ) {
        boolean admin = "ADMIN".equalsIgnoreCase(user.getRole());
        return exerciseService.getExercises(
                keyword,
                admin && Boolean.TRUE.equals(includeInactive)
        );
    }

    @GetMapping("/page")
    public PageResponse<ExerciseResponse> getExercisesPage(
            @AuthenticationPrincipal User user,
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) Boolean includeInactive,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size
    ) {
        boolean admin = "ADMIN".equalsIgnoreCase(user.getRole());
        return exerciseService.getExercisesPage(
                keyword,
                admin && Boolean.TRUE.equals(includeInactive),
                page,
                size
        );
    }

    @GetMapping("/mine")
    public List<ExerciseResponse> getMySubmissions(
            @AuthenticationPrincipal User user
    ) {
        return exerciseService.getMySubmissions(user);
    }

    @PostMapping
    public ExerciseResponse create(@Valid @RequestBody CreateExerciseRequest request) {
        return exerciseService.create(request);
    }

    @PostMapping("/suggestions")
    public ExerciseResponse suggest(
            @AuthenticationPrincipal User user,
            @Valid @RequestBody CreateExerciseRequest request
    ) {
        return exerciseService.createSuggestion(user, request);
    }

    @PatchMapping("/{id}/review")
    public ExerciseResponse review(
            @PathVariable String id,
            @Valid @RequestBody CatalogReviewRequest request
    ) {
        return exerciseService.review(id, request);
    }

    @PutMapping("/{id}")
    public ExerciseResponse update(
            @PathVariable String id,
            @Valid @RequestBody UpdateExerciseRequest request
    ) {
        return exerciseService.update(id, request);
    }

    @DeleteMapping("/{id}")
    public void delete(@PathVariable String id) {
        exerciseService.softDelete(id);
    }

    @PatchMapping("/{id}/restore")
    public ExerciseResponse restore(@PathVariable String id) {
        return exerciseService.restore(id);
    }
}

