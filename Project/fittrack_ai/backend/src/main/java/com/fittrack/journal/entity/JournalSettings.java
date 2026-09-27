package com.fittrack.journal.entity;

import com.fittrack.user.entity.User;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;
import java.time.LocalTime;

@Entity
@Table(name = "journal_settings")
@Getter @Setter @Builder @NoArgsConstructor @AllArgsConstructor
public class JournalSettings {
    @Id
    private String userId;
    @OneToOne(fetch = FetchType.LAZY, optional = false)
    @MapsId
    @JoinColumn(name = "user_id")
    private User user;
    @Column(nullable = false)
    private Boolean reminderEnabled;
    @Column(nullable = false)
    private LocalTime reminderTime;
    @Column(nullable = false)
    private LocalDateTime updatedAt;

    @PrePersist @PreUpdate
    void touch() {
        if (reminderEnabled == null) reminderEnabled = false;
        if (reminderTime == null) reminderTime = LocalTime.of(21, 30);
        updatedAt = LocalDateTime.now();
    }
}
