package com.fittrack.auth.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.Builder;
import lombok.Getter;

@Getter
@Builder(toBuilder = true)
@JsonInclude(JsonInclude.Include.NON_NULL)
public class AuthResponse {
    private String token;
    private String tokenType;
    private String userId;
    private String email;
    private String fullName;
    private String role;
    private Boolean lunchEnabled;
    private Boolean fitnessEnabled;
    private Boolean healthEnabled;
    private Boolean chatbotEnabled;
    private Boolean todoEnabled;
    private Boolean scheduleEnabled;
    private Boolean passwordChangeRequired;
    private String refreshToken;
}
