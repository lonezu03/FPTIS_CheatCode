package com.fittrack.bodytracking.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;

import java.time.LocalDate;
import java.time.LocalDateTime;

public final class ProgressPhotoDtos {
    private ProgressPhotoDtos() {}

    public record ProgressPhotoRequest(
            @NotBlank @Size(max = 2_000_000) String imageUrl,
            LocalDate takenDate,
            @Size(max = 30) String pose,
            @Size(max = 500) String note,
            @Positive Double weight
    ) {}

    public record ProgressPhotoResponse(
            String id,
            String imageUrl,
            LocalDate takenDate,
            String pose,
            String note,
            Double weight,
            LocalDateTime createdAt
    ) {}
}
