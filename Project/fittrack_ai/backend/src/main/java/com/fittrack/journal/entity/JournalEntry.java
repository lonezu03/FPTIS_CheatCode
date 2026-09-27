package com.fittrack.journal.entity;

import com.fittrack.user.entity.User;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.*;

@Entity
@Table(name = "journal_entries")
@Getter @Setter @Builder @NoArgsConstructor @AllArgsConstructor
public class JournalEntry {
    @Id @GeneratedValue(strategy = GenerationType.UUID)
    private String id;
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;
    @Column(nullable = false)
    private LocalDate entryDate;
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private JournalOrigin origin;
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "prompt_id")
    private JournalPrompt prompt;
    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "prompt_display_id", unique = true)
    private JournalPromptDisplay promptDisplay;
    @Column(length = 200)
    private String title;
    @Column(nullable = false, columnDefinition = "text")
    private String body;
    @Enumerated(EnumType.STRING)
    @Column(length = 20)
    private JournalMood mood;
    @Column(nullable = false)
    private LocalDateTime createdAt;
    @Column(nullable = false)
    private LocalDateTime updatedAt;
    private LocalDateTime archivedAt;

    @ManyToMany
    @JoinTable(name="journal_entry_tag_links", joinColumns=@JoinColumn(name="entry_id"), inverseJoinColumns=@JoinColumn(name="tag_id"))
    @OrderBy("name ASC") @Builder.Default
    private Set<JournalTag> tags = new LinkedHashSet<>();

    @OneToMany(mappedBy="entry", cascade=CascadeType.ALL, orphanRemoval=true)
    @OrderBy("sortOrder ASC") @Builder.Default
    private List<JournalEntryImage> images = new ArrayList<>();

    @PrePersist
    void onCreate() {
        var now = LocalDateTime.now();
        if (createdAt == null) createdAt = now;
        updatedAt = now;
    }
    @PreUpdate
    void onUpdate() { updatedAt = LocalDateTime.now(); }
}
