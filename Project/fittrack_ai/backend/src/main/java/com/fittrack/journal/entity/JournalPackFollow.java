package com.fittrack.journal.entity;

import com.fittrack.user.entity.User;
import jakarta.persistence.*;
import lombok.*;
import java.io.Serializable;
import java.time.LocalDateTime;

@Entity @Table(name="journal_pack_follows") @IdClass(JournalPackFollow.Key.class)
@Getter @Setter @Builder @NoArgsConstructor @AllArgsConstructor
public class JournalPackFollow {
    @Id @ManyToOne(fetch=FetchType.LAZY) @JoinColumn(name="user_id") private User user;
    @Id @ManyToOne(fetch=FetchType.LAZY) @JoinColumn(name="pack_id") private JournalPromptPack pack;
    @Column(nullable=false) private LocalDateTime createdAt;
    @PrePersist void create(){if(createdAt==null)createdAt=LocalDateTime.now();}
    @Getter @Setter @NoArgsConstructor @AllArgsConstructor @EqualsAndHashCode
    public static class Key implements Serializable { private String user; private String pack; }
}
