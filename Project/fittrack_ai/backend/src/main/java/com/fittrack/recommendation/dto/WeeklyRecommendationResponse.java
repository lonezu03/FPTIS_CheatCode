package com.fittrack.recommendation.dto;

import lombok.Builder;
import lombok.Getter;

import java.time.LocalDate;
import java.util.List;

@Getter
@Builder
public class WeeklyRecommendationResponse {
    private LocalDate fromDate;
    private LocalDate toDate;
    private String summary;
    private List<RecommendationItemResponse> recommendations;
}
