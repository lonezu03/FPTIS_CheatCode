package com.fittrack.journal.entity;

import com.fittrack.user.entity.User;
import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity @Table(name="journal_unlock_sessions")
@Getter @Setter @Builder @NoArgsConstructor @AllArgsConstructor
public class JournalUnlockSession {
    @Id @GeneratedValue(strategy=GenerationType.UUID) private String id;
    @ManyToOne(fetch=FetchType.LAZY,optional=false) @JoinColumn(name="user_id") private User user;
    @Column(nullable=false,length=64,unique=true) private String tokenHash;
    @Column(nullable=false) private LocalDateTime expiresAt;
    @Column(nullable=false) private LocalDateTime createdAt;
    @PrePersist void create(){if(createdAt==null)createdAt=LocalDateTime.now();}
}
