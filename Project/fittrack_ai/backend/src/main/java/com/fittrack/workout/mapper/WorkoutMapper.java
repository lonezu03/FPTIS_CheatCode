package com.fittrack.workout.mapper;

import com.fittrack.workout.dto.ExerciseResponse;
import com.fittrack.workout.dto.WorkoutSessionResponse;
import com.fittrack.workout.dto.WorkoutSetResponse;
import com.fittrack.workout.entity.Exercise;
import com.fittrack.workout.entity.WorkoutSession;
import com.fittrack.workout.entity.WorkoutSet;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
public class WorkoutMapper {

    public ExerciseResponse toExerciseResponse(Exercise exercise) {
        return ExerciseResponse.builder()
                .id(exercise.getId())
                .name(exercise.getName())
                .muscleGroup(exercise.getMuscleGroup())
                .equipment(exercise.getEquipment())
                .description(exercise.getDescription())
                .custom(exercise.getCustom())
                .active(exercise.getActive())
                .build();
    }

    public List<ExerciseResponse> toExerciseResponseList(List<Exercise> exercises) {
        return exercises.stream()
                .map(this::toExerciseResponse)
                .toList();
    }

    public WorkoutSetResponse toWorkoutSetResponse(WorkoutSet set) {
        Exercise exercise = set.getExercise();

        return WorkoutSetResponse.builder()
                .id(set.getId())
                .exerciseId(exercise.getId())
                .exerciseName(exercise.getName())
                .muscleGroup(exercise.getMuscleGroup())
                .setNumber(set.getSetNumber())
                .weight(set.getWeight())
                .reps(set.getReps())
                .rir(set.getRir())
                .build();
    }

    public WorkoutSessionResponse toWorkoutSessionResponse(WorkoutSession session) {
        return WorkoutSessionResponse.builder()
                .id(session.getId())
                .sessionDate(session.getSessionDate())
                .note(session.getNote())
                .durationMinutes(session.getDurationMinutes())
                .createdAt(session.getCreatedAt())
                .sets(session.getSets().stream()
                        .map(this::toWorkoutSetResponse)
                        .toList())
                .build();
    }

    public List<WorkoutSessionResponse> toWorkoutSessionResponseList(List<WorkoutSession> sessions) {
        return sessions.stream()
                .map(this::toWorkoutSessionResponse)
                .toList();
    }
}

