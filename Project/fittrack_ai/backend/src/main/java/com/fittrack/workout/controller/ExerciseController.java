package com.fittrack.workout.controller;

import com.fittrack.workout.dto.CreateExerciseRequest;
import com.fittrack.workout.dto.ExerciseResponse;
import com.fittrack.workout.dto.UpdateExerciseRequest;
import com.fittrack.workout.service.ExerciseService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/exercises")
@RequiredArgsConstructor
public class ExerciseController {

    private final ExerciseService exerciseService;

    @GetMapping
    public List<ExerciseResponse> getExercises(
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) Boolean includeInactive
    ) {
        return exerciseService.getExercises(keyword, includeInactive);
    }

    @PostMapping
    public ExerciseResponse create(@RequestBody CreateExerciseRequest request) {
        return exerciseService.create(request);
    }

    @PutMapping("/{id}")
    public ExerciseResponse update(
            @PathVariable String id,
            @RequestBody UpdateExerciseRequest request
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

