package com.fittrack.recommendation.dto;

import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class RecommendationItemResponse {
    private String type;
    private String severity;
    private String title;
    private String message;
    private String action;
}
