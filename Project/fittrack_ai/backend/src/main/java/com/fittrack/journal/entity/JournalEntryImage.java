package com.fittrack.journal.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity @Table(name="journal_entry_images")
@Getter @Setter @Builder @NoArgsConstructor @AllArgsConstructor
public class JournalEntryImage {
    @Id @GeneratedValue(strategy=GenerationType.UUID) private String id;
    @ManyToOne(fetch=FetchType.LAZY,optional=false) @JoinColumn(name="entry_id") private JournalEntry entry;
    @Column(nullable=false,columnDefinition="text") private String imageUrl;
    @Column(nullable=false) private Integer sortOrder;
    @Column(nullable=false) private LocalDateTime createdAt;
    @PrePersist void create(){if(createdAt==null)createdAt=LocalDateTime.now();if(sortOrder==null)sortOrder=0;}
}
