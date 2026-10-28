package com.fittrack.workoutplan.entity;

import com.fittrack.workout.entity.Exercise;
import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "workout_plan_exercises")
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class WorkoutPlanExercise {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private String id;

    @ManyToOne(fetch = FetchType.LAZY)
    private WorkoutPlanDay day;

    @ManyToOne(fetch = FetchType.LAZY)
    private Exercise exercise;

    private Integer exerciseOrder;

    private Integer targetSets;

    private Integer targetReps;

    private Double targetWeight;

    private Integer targetRir;
    private Integer restSeconds;
    private Integer minReps;
    private Integer maxReps;
    @Column(length = 1000)
    private String coachingNote;
    @Column(length = 60)
    private String groupKey;
    @Column(length = 12)
    private String groupType;
    private Integer groupRounds;
    private Integer betweenExerciseRestSeconds;
    private Integer betweenRoundRestSeconds;
}

