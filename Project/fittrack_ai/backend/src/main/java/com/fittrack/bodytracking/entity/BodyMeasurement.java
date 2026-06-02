package com.fittrack.bodytracking.entity;

import com.fittrack.user.entity.User;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "body_measurements")
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BodyMeasurement {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private String id;

    @ManyToOne(fetch = FetchType.LAZY)
    private User user;

    private Double weight;
    private Double waist;
    private Double chest;
    private Double arm;
    private Double thigh;

    private LocalDate recordDate;
    private LocalDateTime createdAt;

    @PrePersist
    public void onCreate() {
        this.createdAt = LocalDateTime.now();

        if (this.recordDate == null) {
            this.recordDate = LocalDate.now();
        }
    }
}

