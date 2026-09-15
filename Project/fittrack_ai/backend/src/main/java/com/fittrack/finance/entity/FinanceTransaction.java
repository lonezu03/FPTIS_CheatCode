package com.fittrack.finance.entity;

import com.fittrack.user.entity.User;
import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity @Table(name = "finance_transactions")
@Getter @Setter @Builder @NoArgsConstructor @AllArgsConstructor
public class FinanceTransaction {
    @Id @GeneratedValue(strategy = GenerationType.UUID) private String id;
    @ManyToOne(fetch = FetchType.LAZY, optional = false) @JoinColumn(name = "user_id") private User user;
    @ManyToOne(fetch = FetchType.LAZY, optional = false) @JoinColumn(name = "account_id") private FinanceAccount account;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "destination_account_id") private FinanceAccount destinationAccount;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "category_id") private FinanceCategory category;
    @Column(length = 30) private String expenseNature;
    @Column(nullable = false, length = 20) private String type;
    @Column(nullable = false, precision = 18, scale = 2) private BigDecimal amount;
    @Column(nullable = false) private LocalDateTime occurredAt;
    @Column(length = 160) private String merchant;
    @Column(length = 1000) private String note;
    @Column(length = 50) private String sourceType;
    private String sourceId;
    @Column(nullable = false, length = 20) private String status;
    @Column(nullable = false) private LocalDateTime createdAt;
    @Column(nullable = false) private LocalDateTime updatedAt;
    private LocalDateTime deletedAt;
    @PrePersist void create(){var now=LocalDateTime.now();createdAt=now;updatedAt=now;if(status==null)status="POSTED";}
    @PreUpdate void update(){updatedAt=LocalDateTime.now();}
}
