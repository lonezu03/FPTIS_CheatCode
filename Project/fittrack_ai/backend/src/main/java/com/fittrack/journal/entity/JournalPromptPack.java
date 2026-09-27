package com.fittrack.journal.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity @Table(name="journal_prompt_packs")
@Getter @Setter @Builder @NoArgsConstructor @AllArgsConstructor
public class JournalPromptPack {
    @Id @GeneratedValue(strategy=GenerationType.UUID) private String id;
    @Column(nullable=false,length=120) private String name;
    @Column(length=500) private String description;
    @Column(length=20) private String icon;
    @Column(nullable=false) private Boolean active;
    @Column(nullable=false) private Integer sortOrder;
    @Column(nullable=false) private LocalDateTime createdAt;
    @Column(nullable=false) private LocalDateTime updatedAt;
    @PrePersist void create(){var now=LocalDateTime.now();if(createdAt==null)createdAt=now;updatedAt=now;if(active==null)active=true;if(sortOrder==null)sortOrder=0;}
    @PreUpdate void update(){updatedAt=LocalDateTime.now();}
}
