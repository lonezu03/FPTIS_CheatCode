package com.fittrack.nutrition.dto;

import lombok.Builder;
import lombok.Getter;

import java.time.LocalDateTime;

@Getter
@Builder
public class WaterLogResponse {
    private String id;
    private Integer amountMl;
    private LocalDateTime loggedAt;
}
