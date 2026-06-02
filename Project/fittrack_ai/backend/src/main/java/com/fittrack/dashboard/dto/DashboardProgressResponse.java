package com.fittrack.dashboard.dto;

import lombok.Builder;
import lombok.Getter;

import java.util.List;

@Getter
@Builder
public class DashboardProgressResponse {
    private List<ProgressPointResponse> points;
}

