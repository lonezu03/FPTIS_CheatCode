package com.fittrack.workout.dto;

import com.fittrack.workout.entity.WorkoutSetType;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.AssertTrue;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.PositiveOrZero;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class CreateWorkoutSetRequest {
    @NotBlank
    private String exerciseId;
    @jakarta.validation.constraints.Size(max=255)
    private String originalExerciseId;
    @jakarta.validation.constraints.Pattern(regexp="MANUAL|ALTERNATIVE")
    private String replacementKind;

    @NotNull
    @Positive
    private Integer setNumber;
    @jakarta.validation.constraints.Size(max = 60)
    private String groupKey;
    @jakarta.validation.constraints.Pattern(regexp = "SUPERSET|CIRCUIT")
    private String groupType;
    @Min(1) @Max(20)
    private Integer groupRounds;
    @Min(0) @Max(1800)
    private Integer betweenExerciseRestSeconds;
    @Min(0) @Max(1800)
    private Integer betweenRoundRestSeconds;

    @Min(1)
    @Max(50)
    private Integer exerciseOrder;

    private WorkoutSetType setType;

    @NotNull
    @PositiveOrZero
    @Max(2000)
    private Double weight;

    @NotNull
    @Positive
    @Max(100)
    private Integer reps;

    @NotNull
    @Min(0)
    @Max(10)
    private Integer rir;

    @Min(0)
    @Max(1800)
    private Integer restSeconds;

    @AssertTrue(message = "Only completed workout sets can be saved")
    private Boolean completed;
}
