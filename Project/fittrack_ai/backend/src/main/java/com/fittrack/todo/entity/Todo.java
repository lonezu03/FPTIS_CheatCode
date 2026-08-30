package com.fittrack.todo.entity;

import com.fittrack.user.entity.User;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "todos")
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Todo {
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
    @Column(nullable = false, length = 20)
    private TodoStatus status;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private TodoPriority priority;

    private LocalDateTime startAt;
    private LocalDateTime dueAt;

    @Column(name = "estimated_minutes")
    private Integer estimatedMinutes;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30)
    private TodoCategory category;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private RecurrenceRule recurrenceRule;

    @Column(nullable = false)
    private Integer recurrenceInterval;

    @Column(length = 100)
    private String daysOfWeek;

    @Column(length = 255)
    private String recurringSeriesId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30)
    private RecurrenceBasis recurrenceBasis;

    private LocalDateTime recurrenceEndAt;
    private Integer recurrenceMaxOccurrences;

    @Column(nullable = false)
    private Integer occurrenceNumber;

    private LocalDateTime completedAt;
    private LocalDateTime skippedAt;

    private LocalDateTime reminderAt;
    private LocalDateTime reminderSentAt;

    @Column(nullable = false)
    private Boolean reminderEnabled;

    @Column(nullable = false)
    private LocalDateTime createdAt;

    @Column(nullable = false)
    private LocalDateTime updatedAt;

    @OneToMany(mappedBy = "todo", cascade = CascadeType.ALL, orphanRemoval = true)
    @OrderBy("sortOrder ASC")
    @Builder.Default
    private List<TodoSubtask> subtasks = new ArrayList<>();

    @PrePersist
    void onCreate() {
        LocalDateTime now = LocalDateTime.now();
        createdAt = now;
        updatedAt = now;
        if (status == null) status = TodoStatus.OPEN;
        if (priority == null) priority = TodoPriority.MEDIUM;
        if (category == null) category = TodoCategory.PERSONAL;
        if (recurrenceRule == null) recurrenceRule = RecurrenceRule.NONE;
        if (recurrenceBasis == null) recurrenceBasis = RecurrenceBasis.SCHEDULED_DATE;
        if (recurrenceInterval == null || recurrenceInterval < 1) recurrenceInterval = 1;
        if (occurrenceNumber == null || occurrenceNumber < 1) occurrenceNumber = 1;
        if (reminderEnabled == null) reminderEnabled = false;
    }

    @PreUpdate
    void onUpdate() {
        updatedAt = LocalDateTime.now();
    }

    public enum TodoStatus { OPEN, IN_PROGRESS, DONE, SKIPPED, CANCELLED, ARCHIVED }
    public enum TodoPriority { LOW, MEDIUM, HIGH }
    public enum TodoCategory { WORK, STUDY, PERSONAL, HEALTH, FINANCE, SHOPPING }
    public enum RecurrenceRule { NONE, DAILY, WEEKLY, MONTHLY, YEARLY, CUSTOM }
    public enum RecurrenceBasis { SCHEDULED_DATE, COMPLETION_DATE }
}
