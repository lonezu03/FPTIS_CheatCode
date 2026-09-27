package com.fittrack.journal.entity;

import com.fittrack.user.entity.User;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "journal_prompt_displays")
@Getter @Setter @Builder @NoArgsConstructor @AllArgsConstructor
public class JournalPromptDisplay {
    @Id @GeneratedValue(strategy = GenerationType.UUID)
    private String id;
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "prompt_id", nullable = false)
    private JournalPrompt prompt;
    @Column(nullable = false)
    private LocalDate displayDate;
    @Column(nullable = false)
    private Integer cycleNumber;
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private JournalDisplayStatus status;
    @Column(nullable = false)
    private LocalDateTime createdAt;
    private LocalDateTime answeredAt;
    private LocalDateTime skippedAt;

    @PrePersist
    void onCreate() {
        if (createdAt == null) createdAt = LocalDateTime.now();
        if (status == null) status = JournalDisplayStatus.ASSIGNED;
    }
}
