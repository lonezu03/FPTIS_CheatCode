package com.fittrack.user.dto;

import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class UserProfileResponse {
    private String id;
    private String email;
    private String fullName;
    private String gender;
    private Integer age;
    private Double height;
    private Double weight;
    private String goal;
    private String activityLevel;

    private Double bmr;
    private Double tdee;
    private Double targetCalories;
    private Double targetProtein;
    private Double targetCarbs;
    private Double targetFat;
}

