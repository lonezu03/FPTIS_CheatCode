package com.fittrack.lunch.entity;

import com.fittrack.user.entity.User;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(
        name = "lunch_orders",
        indexes = {
                @Index(name = "idx_lunch_orders_payment_status", columnList = "payment_status"),
                @Index(name = "idx_lunch_orders_created_at", columnList = "created_at"),
                @Index(
                        name = "idx_lunch_orders_menu_beneficiary_status_created_at",
                        columnList = "menu_id, beneficiary_id, status, created_at"
                )
        }
)
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class LunchOrder {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private String id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "menu_id", nullable = false)
    private LunchMenu menu;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "beneficiary_id", nullable = false)
    private User beneficiary;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "payer_id")
    private User payer;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "ordered_by_id", nullable = false)
    private User orderedBy;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private LunchSelectionType selectionType;

    @Column(nullable = false)
    private Long price;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30)
    private LunchPaymentStatus paymentStatus;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private LunchOrderStatus status;

    @Column(length = 500)
    private String note;

    /**
     * Client-generated idempotency key for a multi-portion checkout. Null for
     * the original single-portion endpoint and legacy orders.
     */
    @Column(name = "batch_request_id", length = 64)
    private String batchRequestId;

    @Column(name = "batch_position")
    private Integer batchPosition;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "external_confirmed_by_id")
    private User externalConfirmedBy;

    private LocalDateTime externalConfirmedAt;

    @Column(length = 500)
    private String externalPaymentNote;

    @OneToMany(mappedBy = "order", cascade = CascadeType.ALL, orphanRemoval = true)
    @OrderBy("sortOrder ASC")
    @Builder.Default
    private List<LunchOrderItem> items = new ArrayList<>();

    @Column(nullable = false)
    private LocalDateTime createdAt;

    @Column(nullable = false)
    private LocalDateTime updatedAt;

    private LocalDateTime cancelledAt;

    @Version
    private Long version;

    @PrePersist
    public void onCreate() {
        LocalDateTime now = LocalDateTime.now();
        if (this.createdAt == null) {
            this.createdAt = now;
        }
        this.updatedAt = now;
        if (this.status == null) {
            this.status = LunchOrderStatus.ACTIVE;
        }
    }

    @PreUpdate
    public void onUpdate() {
        this.updatedAt = LocalDateTime.now();
    }
}
