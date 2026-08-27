package com.fittrack.todo.entity;

import com.fittrack.user.entity.User;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

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

    private LocalDateTime dueAt;
    private LocalDateTime reminderAt;
    private LocalDateTime reminderSentAt;

    @Column(nullable = false)
    private Boolean reminderEnabled;

    @Column(nullable = false)
    private LocalDateTime createdAt;

    @Column(nullable = false)
    private LocalDateTime updatedAt;

    @PrePersist
    void onCreate() {
        LocalDateTime now = LocalDateTime.now();
        createdAt = now;
        updatedAt = now;
        if (status == null) status = TodoStatus.OPEN;
        if (priority == null) priority = TodoPriority.MEDIUM;
        if (reminderEnabled == null) reminderEnabled = false;
    }

    @PreUpdate
    void onUpdate() {
        updatedAt = LocalDateTime.now();
    }

    public enum TodoStatus { OPEN, IN_PROGRESS, DONE, ARCHIVED }
    public enum TodoPriority { LOW, MEDIUM, HIGH }
}
