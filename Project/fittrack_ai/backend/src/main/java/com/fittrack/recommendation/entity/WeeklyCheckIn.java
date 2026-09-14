package com.fittrack.recommendation.entity;

import com.fittrack.user.entity.User;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "weekly_checkins")
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class WeeklyCheckIn {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private String id;
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;
    private LocalDate weekStart;
    private LocalDate weekEnd;
    private String status;
    private Boolean dataSufficient;
    private Double confidencePercent;
    private Integer completeDays;
    private Integer workoutDays;
    private Double weightChange;
    private Double currentCalories;
    private Double proposedCalories;
    private Double currentProtein;
    private Double proposedProtein;
    @Column(length = 1000)
    private String rationale;
    private LocalDateTime createdAt;
    private LocalDateTime decidedAt;

    @PrePersist
    void create() {
        createdAt = LocalDateTime.now();
        if (status == null) status = "PENDING";
    }
}
