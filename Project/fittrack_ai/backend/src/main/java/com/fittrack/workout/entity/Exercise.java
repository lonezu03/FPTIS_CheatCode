package com.fittrack.workout.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "exercises")
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Exercise {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private String id;

    @Column(nullable = false)
    private String name;

    private String muscleGroup;

    private String equipment;

    private String description;

    private Boolean custom;

    private Boolean active;

    private LocalDateTime createdAt;

    @PrePersist
    public void onCreate() {
        this.createdAt = LocalDateTime.now();

        if (this.custom == null) {
            this.custom = false;
        }

        if (this.active == null) {
            this.active = true;
        }
    }
}