package com.fittrack.lunch.entity;

import com.fittrack.user.entity.User;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "lunch_menus")
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class LunchMenu {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private String id;

    @Column(name = "menu_date", nullable = false)
    private LocalDate menuDate;

    @Column(nullable = false)
    private String orderLabel;

    private String vendorName;

    @Column(nullable = false)
    private LocalDateTime cutoffAt;

    @Column(nullable = false)
    private Long price;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private LunchMenuStatus status;

    @Column(nullable = false, columnDefinition = "text")
    private String rawMenuText;

    @Column(columnDefinition = "text")
    private String summaryOrderText;

    private LocalDateTime summarizedAt;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "created_by_id", nullable = false)
    private User createdBy;

    @OneToMany(mappedBy = "menu", cascade = CascadeType.ALL, orphanRemoval = true)
    @OrderBy("sortOrder ASC")
    @Builder.Default
    private List<LunchMenuItem> items = new ArrayList<>();

    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(nullable = false)
    private LocalDateTime updatedAt;

    @Version
    private Long version;

    @PrePersist
    public void onCreate() {
        LocalDateTime now = LocalDateTime.now();
        this.createdAt = now;
        this.updatedAt = now;
        if (this.price == null) {
            this.price = 35_000L;
        }
        if (this.status == null) {
            this.status = LunchMenuStatus.OPEN;
        }
    }

    @PreUpdate
    public void onUpdate() {
        this.updatedAt = LocalDateTime.now();
    }
}
