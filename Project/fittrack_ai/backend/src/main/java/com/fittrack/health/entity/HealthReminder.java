package com.fittrack.health.entity;

import com.fittrack.user.entity.User;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;

@Entity
@Table(
        name = "health_reminders",
        indexes = @Index(
                name = "idx_health_reminder_user",
                columnList = "user_id"
        )
)
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class HealthReminder {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private String id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(nullable = false, length = 30)
    private String type;

    @Column(nullable = false, length = 180)
    private String title;

    @Column(length = 500)
    private String message;

    @Column(nullable = false)
    private LocalTime reminderTime;

    @Column(nullable = false, length = 100)
    private String daysOfWeek;

    @Column(nullable = false)
    private Boolean enabled;

    private LocalDate lastTriggeredDate;

    private LocalDateTime lastTriggeredAt;

    private LocalDateTime nextRunAt;

    @Version
    private Long version;

    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    public void onCreate() {
        if (enabled == null) {
            enabled = true;
        }
        if (createdAt == null) {
            createdAt = LocalDateTime.now();
        }
    }
}
