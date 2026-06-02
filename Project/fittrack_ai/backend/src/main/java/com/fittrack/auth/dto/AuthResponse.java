package com.fittrack.auth.dto;

import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class AuthResponse {
    private String token;
    private String tokenType;
    private String userId;
    private String email;
    private String fullName;
}