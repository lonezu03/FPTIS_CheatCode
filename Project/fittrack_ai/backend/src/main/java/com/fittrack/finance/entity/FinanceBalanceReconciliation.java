package com.fittrack.finance.entity;

import com.fittrack.user.entity.User;
import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity @Table(name = "finance_balance_reconciliations")
@Getter @Setter @Builder @NoArgsConstructor @AllArgsConstructor
public class FinanceBalanceReconciliation {
    @Id @GeneratedValue(strategy = GenerationType.UUID) private String id;
    @ManyToOne(fetch = FetchType.LAZY, optional = false) @JoinColumn(name = "user_id") private User user;
    @ManyToOne(fetch = FetchType.LAZY, optional = false) @JoinColumn(name = "account_id") private FinanceAccount account;
    @Column(nullable = false, precision = 24, scale = 2) private BigDecimal balanceBefore;
    @Column(nullable = false, precision = 24, scale = 2) private BigDecimal balanceAfter;
    @Column(nullable = false, precision = 24, scale = 2) private BigDecimal difference;
    @Column(nullable = false, precision = 18, scale = 2) private BigDecimal openingBefore;
    @Column(nullable = false, precision = 18, scale = 2) private BigDecimal openingAfter;
    @Column(nullable = false, length = 500) private String note;
    @Column(nullable = false) private LocalDateTime createdAt;
}
