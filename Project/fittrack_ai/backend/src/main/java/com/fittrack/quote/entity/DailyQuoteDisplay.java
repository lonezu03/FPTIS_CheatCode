package com.fittrack.quote.entity;

import com.fittrack.user.entity.User;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(
        name = "daily_quote_displays",
        uniqueConstraints = {
                @UniqueConstraint(name = "uq_daily_quote_user_date", columnNames = {"user_id", "display_date"}),
                @UniqueConstraint(name = "uq_daily_quote_user_quote_cycle", columnNames = {"user_id", "quote_id", "cycle_number"})
        }
)
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DailyQuoteDisplay {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private String id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "quote_id", nullable = false)
    private FavoriteQuote quote;

    @Column(nullable = false)
    private LocalDate displayDate;

    @Column(nullable = false)
    private Integer cycleNumber;

    @Column(nullable = false)
    private LocalDateTime createdAt;

    @PrePersist
    void onCreate() {
        if (createdAt == null) createdAt = LocalDateTime.now();
    }
}
