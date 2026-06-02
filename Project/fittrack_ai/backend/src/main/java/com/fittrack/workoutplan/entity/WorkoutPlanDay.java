package com.fittrack.workoutplan.entity;

import jakarta.persistence.*;
import lombok.*;

import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "workout_plan_days")
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class WorkoutPlanDay {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private String id;

    @ManyToOne(fetch = FetchType.LAZY)
    private WorkoutPlan plan;

    private String name;

    private Integer dayOrder;

    @OneToMany(mappedBy = "day", cascade = CascadeType.ALL, orphanRemoval = true)
    @Builder.Default
    private List<WorkoutPlanExercise> exercises = new ArrayList<>();
}

