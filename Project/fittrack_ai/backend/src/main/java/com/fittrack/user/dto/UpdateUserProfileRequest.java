package com.fittrack.user.dto;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class UpdateUserProfileRequest {
    private String fullName;
    private String gender;
    private Integer age;
    private Double height;
    private Double weight;
    private String goal;
    private String activityLevel;
}

