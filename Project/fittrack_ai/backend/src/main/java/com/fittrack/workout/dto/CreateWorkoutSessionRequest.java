package com.fittrack.workout.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDate;
import java.util.List;

@Getter
@Setter
public class CreateWorkoutSessionRequest {
    @NotNull
    private LocalDate sessionDate;

    @Size(max = 500)
    private String note;

    @NotNull
    @Positive
    @Max(600)
    private Integer durationMinutes;

    @NotEmpty
    @Valid
    private List<CreateWorkoutSetRequest> sets;
}
