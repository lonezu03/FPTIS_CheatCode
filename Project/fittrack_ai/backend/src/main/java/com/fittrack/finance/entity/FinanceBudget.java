package com.fittrack.finance.entity;

import com.fittrack.user.entity.User;
import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity @Table(name = "finance_budgets")
@Getter @Setter @Builder @NoArgsConstructor @AllArgsConstructor
public class FinanceBudget {
    @Id @GeneratedValue(strategy = GenerationType.UUID) private String id;
    @ManyToOne(fetch = FetchType.LAZY, optional = false) @JoinColumn(name = "user_id") private User user;
    @ManyToOne(fetch = FetchType.LAZY, optional = false) @JoinColumn(name = "category_id") private FinanceCategory category;
    @Column(nullable = false) private LocalDate monthStart;
    @Column(nullable = false, precision = 18, scale = 2) private BigDecimal amount;
    @Column(nullable = false) private Boolean rolloverEnabled;
    private LocalDateTime warned80At;
    private LocalDateTime warned100At;
    @Column(nullable = false) private LocalDateTime createdAt;
    @Column(nullable = false) private LocalDateTime updatedAt;
    @PrePersist void create(){var now=LocalDateTime.now();createdAt=now;updatedAt=now;if(rolloverEnabled==null)rolloverEnabled=false;}
    @PreUpdate void update(){updatedAt=LocalDateTime.now();}
}
