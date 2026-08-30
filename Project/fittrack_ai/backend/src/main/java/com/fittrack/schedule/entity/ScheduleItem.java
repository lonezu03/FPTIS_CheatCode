package com.fittrack.schedule.entity;

import com.fittrack.user.entity.User;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "schedule_items")
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ScheduleItem {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private String id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(nullable = false, length = 180)
    private String title;

    @Column(length = 1000)
    private String description;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30)
    private ScheduleCategory category;

    @Column(nullable = false)
    private LocalDateTime startAt;

    private LocalDateTime endAt;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private RepeatRule repeatRule;

    @Column(nullable = false)
    private Integer repeatInterval;

    private LocalDateTime repeatEndAt;

    @Column(length = 100)
    private String daysOfWeek;

    @Column(nullable = false)
    private Integer reminderMinutes;

    @Column(nullable = false)
    private Boolean reminderEnabled;

    @Column(nullable = false)
    private Boolean enabled;

    private LocalDateTime lastRemindedAt;

    @Column(nullable = false)
    private LocalDateTime createdAt;

    @Column(nullable = false)
    private LocalDateTime updatedAt;

    @PrePersist
    void onCreate() {
        LocalDateTime now = LocalDateTime.now();
        createdAt = now;
        updatedAt = now;
        if (category == null) category = ScheduleCategory.PERSONAL;
        if (repeatRule == null) repeatRule = RepeatRule.NONE;
        if (repeatInterval == null || repeatInterval < 1) repeatInterval = 1;
        if (reminderMinutes == null) reminderMinutes = 10;
        if (reminderEnabled == null) reminderEnabled = true;
        if (enabled == null) enabled = true;
    }

    @PreUpdate
    void onUpdate() {
        updatedAt = LocalDateTime.now();
    }

    public enum ScheduleCategory { PERSONAL, WORK, HEALTH, STUDY, MEAL }
    public enum RepeatRule { NONE, DAILY, WEEKLY, MONTHLY, YEARLY }
}
