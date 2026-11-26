package com.fittrack.music.entity;

import com.fittrack.user.entity.User;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneId;

@Entity
@Table(
        name = "music_practice_sessions",
        indexes = @Index(name = "idx_music_practice_user_practiced_on", columnList = "user_id, practiced_on")
)
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MusicPracticeSession {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private String id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 10)
    private MusicInstrument instrument;

    @Column(nullable = false)
    private LocalDate practicedOn;

    @Column(nullable = false)
    private Integer minutes;

    @Column(nullable = false, length = 60)
    private String exerciseKey;

    private Integer bpm;

    @Column(length = 500)
    private String note;

    @Column(nullable = false)
    private LocalDateTime createdAt;

    @PrePersist
    void onCreate() {
        if (createdAt == null) createdAt = LocalDateTime.now(ZoneId.of("Asia/Ho_Chi_Minh"));
    }
}
