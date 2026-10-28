package com.fittrack.workout.entity;

import com.fasterxml.jackson.annotation.JsonBackReference;
import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "workout_sets")
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class WorkoutSet {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private String id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JsonBackReference
    private WorkoutSession session;

    @ManyToOne(fetch = FetchType.LAZY)
    private Exercise exercise;

    private Integer setNumber;
    /** Optional planned exercise provenance; the exercise relation is always the actual exercise. */
    private String originalExerciseId;
    @Column(length=12)
    private String replacementKind;
    @Column(length = 60)
    private String groupKey;
    @Column(length = 12)
    private String groupType;
    private Integer groupRounds;
    private Integer betweenExerciseRestSeconds;
    private Integer betweenRoundRestSeconds;

    @Builder.Default
    private Integer exerciseOrder = 1;

    @Enumerated(EnumType.STRING)
    @Builder.Default
    private WorkoutSetType setType = WorkoutSetType.NORMAL;

    private Double weight;

    private Integer reps;

    private Integer rir;

    @Builder.Default
    private Integer restSeconds = 90;

    @Builder.Default
    private Boolean completed = true;
}
