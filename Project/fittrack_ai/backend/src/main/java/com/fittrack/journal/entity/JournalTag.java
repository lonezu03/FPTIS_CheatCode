package com.fittrack.journal.entity;

import com.fittrack.user.entity.User;
import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity @Table(name="journal_tags")
@Getter @Setter @Builder @NoArgsConstructor @AllArgsConstructor
public class JournalTag {
    @Id @GeneratedValue(strategy=GenerationType.UUID) private String id;
    @ManyToOne(fetch=FetchType.LAZY,optional=false) @JoinColumn(name="user_id") private User user;
    @Column(nullable=false,length=80) private String name;
    @Column(nullable=false) private LocalDateTime createdAt;
    @PrePersist void create(){if(createdAt==null)createdAt=LocalDateTime.now();}
}
