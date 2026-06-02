package com.fittrack.workout.service;

import com.fittrack.workout.dto.CreateExerciseRequest;
import com.fittrack.workout.dto.ExerciseResponse;
import com.fittrack.workout.dto.UpdateExerciseRequest;
import com.fittrack.workout.entity.Exercise;
import com.fittrack.workout.mapper.WorkoutMapper;
import com.fittrack.workout.repository.ExerciseRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class ExerciseService {

    private final ExerciseRepository exerciseRepository;
    private final WorkoutMapper workoutMapper;

    public List<ExerciseResponse> getExercises(String keyword, Boolean includeInactive) {
        boolean showInactive = Boolean.TRUE.equals(includeInactive);

        List<Exercise> exercises;

        if (showInactive) {
            if (keyword == null || keyword.isBlank()) {
                exercises = exerciseRepository.findAllByOrderByNameAsc();
            } else {
                exercises = exerciseRepository.findByNameContainingIgnoreCaseOrderByNameAsc(keyword);
            }
        } else {
            if (keyword == null || keyword.isBlank()) {
                exercises = exerciseRepository.findByActiveTrueOrderByNameAsc();
            } else {
                exercises = exerciseRepository.findByActiveTrueAndNameContainingIgnoreCaseOrderByNameAsc(keyword);
            }
        }

        return workoutMapper.toExerciseResponseList(exercises);
    }

    public ExerciseResponse create(CreateExerciseRequest request) {
        Exercise exercise = Exercise.builder()
                .name(request.getName())
                .muscleGroup(request.getMuscleGroup())
                .equipment(request.getEquipment())
                .description(request.getDescription())
                .custom(true)
                .active(true)
                .build();

        Exercise saved = exerciseRepository.save(exercise);

        return workoutMapper.toExerciseResponse(saved);
    }

    public ExerciseResponse update(String id, UpdateExerciseRequest request) {
        Exercise exercise = exerciseRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Exercise not found"));

        exercise.setName(request.getName());
        exercise.setMuscleGroup(request.getMuscleGroup());
        exercise.setEquipment(request.getEquipment());
        exercise.setDescription(request.getDescription());

        Exercise saved = exerciseRepository.save(exercise);

        return workoutMapper.toExerciseResponse(saved);
    }

    public void softDelete(String id) {
        Exercise exercise = exerciseRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Exercise not found"));

        exercise.setActive(false);

        exerciseRepository.save(exercise);
    }

    public ExerciseResponse restore(String id) {
        Exercise exercise = exerciseRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Exercise not found"));

        exercise.setActive(true);

        Exercise saved = exerciseRepository.save(exercise);

        return workoutMapper.toExerciseResponse(saved);
    }
}

