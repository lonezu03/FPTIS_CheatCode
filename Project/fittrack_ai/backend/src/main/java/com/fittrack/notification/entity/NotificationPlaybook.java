package com.fittrack.notification.entity;

import com.fittrack.notification.dto.NotificationPlaybookDtos.Category;
import com.fittrack.notification.dto.NotificationPlaybookDtos.ConditionType;
import com.fittrack.notification.dto.NotificationPlaybookDtos.Mode;
import com.fittrack.notification.dto.NotificationPlaybookDtos.RecipientMode;
import com.fittrack.user.entity.User;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.LinkedHashSet;
import java.util.Set;

@Entity
@Table(name = "notification_playbooks")
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class NotificationPlaybook {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private String id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "created_by_id")
    private User createdBy;

    @Column(nullable = false, length = 180)
    private String name;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30)
    private Category category;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private Mode mode;

    @Column(name = "trigger_time", nullable = false)
    private LocalTime triggerTime;

    @Column(name = "days_of_week", nullable = false, length = 100)
    private String daysOfWeek;

    @Column(nullable = false, columnDefinition = "text")
    private String messages;

    @Enumerated(EnumType.STRING)
    @Column(name = "condition_type", nullable = false, length = 30)
    private ConditionType conditionType;

    @Column(precision = 12, scale = 2)
    private BigDecimal threshold;

    @Enumerated(EnumType.STRING)
    @Column(name = "recipient_mode", nullable = false, length = 20)
    private RecipientMode recipientMode;

    @ManyToMany(fetch = FetchType.LAZY)
    @JoinTable(
            name = "notification_playbook_recipients",
            joinColumns = @JoinColumn(name = "playbook_id"),
            inverseJoinColumns = @JoinColumn(name = "user_id")
    )
    @Builder.Default
    private Set<User> recipients = new LinkedHashSet<>();

    @Column(nullable = false)
    private boolean enabled;

    @Column(name = "last_triggered_date")
    private LocalDate lastTriggeredDate;

    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(nullable = false)
    private LocalDateTime updatedAt;

    @PrePersist
    public void onCreate() {
        LocalDateTime now = LocalDateTime.now();
        createdAt = now;
        updatedAt = now;
        if (category == null) category = Category.WELLNESS;
        if (mode == null) mode = Mode.FIXED;
        if (conditionType == null) conditionType = ConditionType.ANY;
        if (recipientMode == null) recipientMode = RecipientMode.ALL_ACTIVE;
        if (daysOfWeek == null || daysOfWeek.isBlank()) {
            daysOfWeek = "MONDAY,TUESDAY,WEDNESDAY,THURSDAY,FRIDAY,SATURDAY,SUNDAY";
        }
    }

    @PreUpdate
    public void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}
