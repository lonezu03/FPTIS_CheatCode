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
    private Boolean nutritionDataSufficient;
    private Integer completeNutritionDays;
    private Integer periodDays;
    private Double nutritionConfidencePercent;
    private List<RecommendationItemResponse> recommendations;
}
