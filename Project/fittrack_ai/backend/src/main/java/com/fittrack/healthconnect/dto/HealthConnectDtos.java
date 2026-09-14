package com.fittrack.healthconnect.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

public final class HealthConnectDtos {
    private HealthConnectDtos() {
    }

    public record SyncRecordRequest(
            @NotBlank @Size(max = 255) String externalId,
            @NotBlank String recordType,
            @Size(max = 160) String sourceName,
            @NotNull LocalDateTime startAt,
            LocalDateTime endAt,
            Double value,
            @Size(max = 40) String unit
    ) {
    }

    public record SyncBatchRequest(
            @NotEmpty @Size(max = 500) List<@Valid SyncRecordRequest> records
    ) {
    }

    public record SyncBatchResponse(int imported, int duplicates, int rejected) {
    }

    public record DailyHealthConnectResponse(
            LocalDate date,
            long steps,
            Double latestWeightKg,
            Double averageHeartRate,
            int exerciseSessions,
            LocalDateTime lastSyncedAt
    ) {
    }
}
