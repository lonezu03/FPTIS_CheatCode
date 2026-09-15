package com.fittrack.finance.entity;

import com.fittrack.user.entity.User;
import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity @Table(name = "finance_recurring_rules")
@Getter @Setter @Builder @NoArgsConstructor @AllArgsConstructor
public class FinanceRecurringRule {
    @Id @GeneratedValue(strategy = GenerationType.UUID) private String id;
    @ManyToOne(fetch = FetchType.LAZY, optional = false) @JoinColumn(name = "user_id") private User user;
    @Column(nullable = false, length = 160) private String name;
    @Column(nullable = false, length = 20) private String transactionType;
    @ManyToOne(fetch = FetchType.LAZY, optional = false) @JoinColumn(name = "account_id") private FinanceAccount account;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "destination_account_id") private FinanceAccount destinationAccount;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "category_id") private FinanceCategory category;
    @Column(length = 30) private String expenseNature;
    @Column(nullable = false, precision = 18, scale = 2) private BigDecimal amount;
    @Column(nullable = false, length = 20) private String frequency;
    @Column(nullable = false) private LocalDate nextDueDate;
    @Column(nullable = false) private Integer remindDaysBefore;
    @Column(nullable = false) private Boolean active;
    private LocalDate lastNotifiedFor;
    @Column(nullable = false) private LocalDateTime createdAt;
    @Column(nullable = false) private LocalDateTime updatedAt;
    @PrePersist void create(){var now=LocalDateTime.now();createdAt=now;updatedAt=now;if(active==null)active=true;if(remindDaysBefore==null)remindDaysBefore=1;}
    @PreUpdate void update(){updatedAt=LocalDateTime.now();}
}
