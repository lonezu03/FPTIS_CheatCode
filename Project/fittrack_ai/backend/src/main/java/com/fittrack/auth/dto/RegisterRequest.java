package com.fittrack.auth.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class RegisterRequest {

    @Email
    @NotBlank
    private String email;

    @NotBlank
    private String password;

    private String fullName;

    private String gender;

    private Integer age;

    private Double height;

    private Double weight;

    private String goal;

    private String activityLevel;
}