package com.fittrack.nutrition.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "foods")
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Food {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private String id;

    @Column(nullable = false)
    private String name;

    private Double calories;

    private Double protein;

    private Double carbs;

    private Double fat;

    private String unit;

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

