package com.fittrack.workout.entity;

import com.fittrack.user.entity.User;
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

    @Column(columnDefinition = "TEXT")
    private String imageUrl;

    private Boolean custom;

    private Boolean active;

    // Existing exercises predate the approval workflow, so they are treated as
    // approved when Hibernate adds this required column to an existing schema.
    @Column(nullable = false, length = 20, columnDefinition = "varchar(20) default 'APPROVED'")
    private String approvalStatus;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "submitted_by_id")
    private User submittedBy;

    @Column(length = 500)
    private String adminNote;

    private LocalDateTime reviewedAt;

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

        if (this.approvalStatus == null) {
            this.approvalStatus = "APPROVED";
        }
    }
}
