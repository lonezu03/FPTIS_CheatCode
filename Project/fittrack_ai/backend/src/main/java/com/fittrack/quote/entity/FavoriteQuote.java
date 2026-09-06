package com.fittrack.quote.entity;

import com.fittrack.user.entity.User;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;
import java.util.LinkedHashSet;
import java.util.Set;

@Entity
@Table(name = "favorite_quotes")
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class FavoriteQuote {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private String id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(nullable = false, columnDefinition = "text")
    private String content;

    @Column(length = 255)
    private String author;

    @Enumerated(EnumType.STRING)
    @Column(length = 30)
    private QuoteSourceType sourceType;

    @Column(length = 500)
    private String sourceTitle;

    @Column(columnDefinition = "text")
    private String sourceUrl;

    @Column(length = 255)
    private String sourceLocation;

    @Column(columnDefinition = "text")
    private String personalNote;

    @Column(nullable = false)
    private Boolean includeInDaily;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private QuoteStatus status;

    @Column(length = 10)
    private String language;

    @Column(nullable = false, length = 64)
    private String contentHash;

    @Column(nullable = false)
    private LocalDateTime createdAt;

    @Column(nullable = false)
    private LocalDateTime updatedAt;

    private LocalDateTime archivedAt;

    @ManyToMany
    @JoinTable(
            name = "quote_tag_links",
            joinColumns = @JoinColumn(name = "quote_id"),
            inverseJoinColumns = @JoinColumn(name = "tag_id")
    )
    @OrderBy("name ASC")
    @Builder.Default
    private Set<QuoteTag> tags = new LinkedHashSet<>();

    @PrePersist
    void onCreate() {
        LocalDateTime now = LocalDateTime.now();
        if (createdAt == null) createdAt = now;
        updatedAt = now;
        if (includeInDaily == null) includeInDaily = true;
        if (status == null) status = QuoteStatus.ACTIVE;
    }

    @PreUpdate
    void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}
