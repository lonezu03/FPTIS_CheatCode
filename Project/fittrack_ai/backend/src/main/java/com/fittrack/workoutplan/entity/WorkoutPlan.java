package com.fittrack.workoutplan.entity;

import com.fittrack.user.entity.User;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "workout_plans")
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class WorkoutPlan {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private String id;

    @ManyToOne(fetch = FetchType.LAZY)
    private User user;

    private String name;

    private String description;

    private LocalDateTime createdAt;

    @OneToMany(mappedBy = "plan", cascade = CascadeType.ALL, orphanRemoval = true)
    @Builder.Default
    private List<WorkoutPlanDay> days = new ArrayList<>();

    @PrePersist
    public void onCreate() {
        this.createdAt = LocalDateTime.now();
    }
}

