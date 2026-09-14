package com.fittrack.bodytracking.entity;

import com.fittrack.user.entity.User;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "progress_photos")
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ProgressPhoto {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private String id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String imageUrl;

    @Column(nullable = false)
    private LocalDate takenDate;

    @Column(nullable = false, length = 30)
    private String pose;

    @Column(length = 500)
    private String note;

    private Double weight;

    @Column(nullable = false)
    private LocalDateTime createdAt;

    @PrePersist
    void onCreate() {
        if (takenDate == null) takenDate = LocalDate.now();
        if (pose == null) pose = "OTHER";
        if (createdAt == null) createdAt = LocalDateTime.now();
    }
}
