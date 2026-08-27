package com.fittrack.user.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "users")
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private String id;

    @Column(nullable = false, unique = true)
    private String email;

    @Column(nullable = false)
    private String password;

    private String fullName;

    private String gender;

    private Integer age;

    private Double height;

    private Double weight;

    private String goal;

    private String activityLevel;

    private String role;

    @Column(nullable = false, columnDefinition = "boolean default true")
    private Boolean active;

    @Column(nullable = false, columnDefinition = "boolean default true")
    private Boolean emailVerified;

    @Column(nullable = false, columnDefinition = "boolean default true")
    private Boolean lunchEnabled;

    @Column(nullable = false, columnDefinition = "boolean default false")
    private Boolean fitnessEnabled;

    @Column(nullable = false, columnDefinition = "boolean default false")
    private Boolean healthEnabled;

    @Column(nullable = false, columnDefinition = "boolean default false")
    private Boolean chatbotEnabled;

    @Column(nullable = false, columnDefinition = "boolean default false")
    private Boolean todoEnabled;

    @Column(nullable = false, columnDefinition = "boolean default false")
    private Boolean scheduleEnabled;

    @Column(nullable = false, columnDefinition = "boolean default false")
    private Boolean passwordChangeRequired;

    @Column(nullable = false, columnDefinition = "bigint default 0")
    private Long tokenVersion;

    @Column(nullable = false, columnDefinition = "boolean default false")
    private Boolean assistantConsent;

    private LocalDateTime assistantConsentAt;

    @Column(nullable = false, columnDefinition = "boolean default false")
    private Boolean emailNotificationsEnabled;

    private LocalDateTime createdAt;

    @PrePersist
    public void onCreate() {
        this.createdAt = LocalDateTime.now();

        if (this.role == null) {
            this.role = "USER";
        }

        if (this.active == null) {
            this.active = true;
        }

        if (this.emailVerified == null) {
            this.emailVerified = true;
        }

        if (this.lunchEnabled == null) {
            this.lunchEnabled = true;
        }

        if (this.fitnessEnabled == null) {
            this.fitnessEnabled = false;
        }

        if (this.healthEnabled == null) {
            this.healthEnabled = false;
        }

        if (this.chatbotEnabled == null) {
            this.chatbotEnabled = false;
        }

        if (this.todoEnabled == null) {
            this.todoEnabled = false;
        }

        if (this.scheduleEnabled == null) {
            this.scheduleEnabled = false;
        }

        if (this.passwordChangeRequired == null) {
            this.passwordChangeRequired = false;
        }

        if (this.tokenVersion == null) {
            this.tokenVersion = 0L;
        }

        if (this.assistantConsent == null) {
            this.assistantConsent = false;
        }

        if (this.emailNotificationsEnabled == null) {
            this.emailNotificationsEnabled = false;
        }
    }
}
