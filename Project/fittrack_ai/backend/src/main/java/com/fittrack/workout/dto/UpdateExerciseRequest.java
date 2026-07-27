package com.fittrack.workout.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class UpdateExerciseRequest {
    @NotBlank
    @Size(max = 255)
    private String name;
    @Size(max = 120)
    private String muscleGroup;
    @Size(max = 120)
    private String equipment;
    @Size(max = 2000)
    private String description;
    @Size(max = 2_000_000)
    private String imageUrl;
}

