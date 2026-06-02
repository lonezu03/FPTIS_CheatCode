package com.fittrack.workoutplan.mapper;

import com.fittrack.workout.entity.Exercise;
import com.fittrack.workoutplan.dto.WorkoutPlanDayResponse;
import com.fittrack.workoutplan.dto.WorkoutPlanExerciseResponse;
import com.fittrack.workoutplan.dto.WorkoutPlanResponse;
import com.fittrack.workoutplan.entity.WorkoutPlan;
import com.fittrack.workoutplan.entity.WorkoutPlanDay;
import com.fittrack.workoutplan.entity.WorkoutPlanExercise;
import org.springframework.stereotype.Component;

import java.util.Comparator;
import java.util.List;

@Component
public class WorkoutPlanMapper {

    public WorkoutPlanResponse toResponse(WorkoutPlan plan) {
        return WorkoutPlanResponse.builder()
                .id(plan.getId())
                .name(plan.getName())
                .description(plan.getDescription())
                .createdAt(plan.getCreatedAt())
                .days(plan.getDays().stream()
                        .sorted(Comparator.comparing(WorkoutPlanDay::getDayOrder))
                        .map(this::toDayResponse)
                        .toList())
                .build();
    }

    public List<WorkoutPlanResponse> toResponseList(List<WorkoutPlan> plans) {
        return plans.stream()
                .map(this::toResponse)
                .toList();
    }

    private WorkoutPlanDayResponse toDayResponse(WorkoutPlanDay day) {
        return WorkoutPlanDayResponse.builder()
                .id(day.getId())
                .name(day.getName())
                .dayOrder(day.getDayOrder())
                .exercises(day.getExercises().stream()
                        .sorted(Comparator.comparing(WorkoutPlanExercise::getExerciseOrder))
                        .map(this::toExerciseResponse)
                        .toList())
                .build();
    }

    private WorkoutPlanExerciseResponse toExerciseResponse(WorkoutPlanExercise planExercise) {
        Exercise exercise = planExercise.getExercise();

        return WorkoutPlanExerciseResponse.builder()
                .id(planExercise.getId())
                .exerciseId(exercise.getId())
                .exerciseName(exercise.getName())
                .muscleGroup(exercise.getMuscleGroup())
                .exerciseOrder(planExercise.getExerciseOrder())
                .targetSets(planExercise.getTargetSets())
                .targetReps(planExercise.getTargetReps())
                .targetWeight(planExercise.getTargetWeight())
                .targetRir(planExercise.getTargetRir())
                .build();
    }
}

