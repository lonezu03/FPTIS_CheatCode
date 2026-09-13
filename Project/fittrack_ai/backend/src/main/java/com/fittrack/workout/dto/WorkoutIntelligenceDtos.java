package com.fittrack.workout.dto;

import com.fittrack.workout.entity.ExercisePreferenceLevel;
import jakarta.validation.constraints.NotNull;

import java.time.LocalDate;
import java.util.List;

public final class WorkoutIntelligenceDtos {

    private WorkoutIntelligenceDtos() {
    }

    public record ProgressionResponse(
            String action,
            Double previousWeight,
            Double suggestedWeight,
            Integer suggestedSets,
            Integer suggestedMinReps,
            Integer suggestedMaxReps,
            Integer targetRir,
            String explanation,
            boolean hasEnoughData
    ) {
    }

    public record PersonalBestResponse(
            String type,
            Double value,
            Double weight,
            Integer reps,
            LocalDate achievedOn
    ) {
    }

    public record NewPersonalRecordResponse(
            String type,
            String exerciseId,
            String exerciseName,
            Double previousValue,
            Double newValue,
            Double weight,
            Integer reps,
            String unit
    ) {
    }

    public record WorkoutIntelligenceResponse(
            String exerciseId,
            String exerciseName,
            PreviousWorkoutPerformanceResponse previousPerformance,
            ProgressionResponse progression,
            List<PersonalBestResponse> personalBests
    ) {
    }

    public record MuscleVolumeResponse(
            String muscleGroup,
            int workingSets,
            int previousWeekSets,
            double totalVolume,
            int changeSets
    ) {
    }

    public record WeeklyVolumeResponse(
            LocalDate weekStart,
            LocalDate weekEnd,
            int totalWorkingSets,
            double totalVolume,
            List<MuscleVolumeResponse> muscleGroups,
            String disclaimer
    ) {
    }

    public record ExercisePreferenceRequest(
            @NotNull ExercisePreferenceLevel preference
    ) {
    }

    public record ExercisePreferenceResponse(
            String exerciseId,
            ExercisePreferenceLevel preference
    ) {
    }

    public record AlternativeExerciseResponse(
            ExerciseResponse exercise,
            ExercisePreferenceLevel preference,
            boolean sameEquipment
    ) {
    }
}
