package com.fittrack.nutrition.entity;

import com.fittrack.user.entity.User;
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

    private Double fiber;

    private Double sugar;

    private Double sodium;

    private Double potassium;

    private Double calcium;

    private Double iron;

    @Column(name = "vitamin_c")
    private Double vitaminC;

    private Double water;

    private String unit;

    private Double servingSizeGrams;

    @Column(nullable = false, length = 30)
    @Builder.Default
    private String dataSourceType = "ESTIMATED";

    private String dataSourceName;

    @Column(nullable = false)
    @Builder.Default
    private Boolean verified = false;

    @Column(columnDefinition = "TEXT")
    private String imageUrl;

    private Boolean custom;

    private Boolean active;

    // The database already contains foods created before moderation was added.
    // A database default lets Hibernate add the NOT NULL column without
    // invalidating those existing rows during an update migration.
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

        if (this.dataSourceType == null) {
            this.dataSourceType = "ESTIMATED";
        }

        if (this.verified == null) {
            this.verified = false;
        }
    }
}

