package com.fittrack.dashboard.dto;

import lombok.Builder;
import lombok.Getter;

import java.time.LocalDateTime;

@Getter
@Builder
public class DashboardAgendaItemResponse {
    private String sourceType;
    private String sourceId;
    private String title;
    private String category;
    private String status;
    private LocalDateTime startAt;
    private LocalDateTime endAt;
}
