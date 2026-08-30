package com.fittrack.nutrition.dto;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDateTime;

@Getter
@Setter
public class WaterLogRequest {
    @NotNull
    @Min(1)
    @Max(10_000)
    private Integer amountMl;

    private LocalDateTime loggedAt;
}
