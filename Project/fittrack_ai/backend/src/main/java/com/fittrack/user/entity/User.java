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
    }
}
