package com.fittrack.achievement.dto;

import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class AchievementResponse {
    private String code;
    private String title;
    private String description;
    private Boolean unlocked;
    private Integer progress;
    private Integer target;
}

