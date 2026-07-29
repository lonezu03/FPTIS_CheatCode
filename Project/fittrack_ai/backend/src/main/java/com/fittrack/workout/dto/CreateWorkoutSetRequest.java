package com.fittrack.workout.dto;

import jakarta.validation.constraints.Max;
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

    @NotNull
    @Positive
    private Integer setNumber;

    @NotNull
    @PositiveOrZero
    private Double weight;

    @NotNull
    @Positive
    private Integer reps;

    @NotNull
    @Min(0)
    @Max(10)
    private Integer rir;
}
