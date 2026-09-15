package com.fittrack.finance.entity;

import com.fittrack.user.entity.User;
import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity @Table(name = "finance_accounts")
@Getter @Setter @Builder @NoArgsConstructor @AllArgsConstructor
public class FinanceAccount {
    @Id @GeneratedValue(strategy = GenerationType.UUID) private String id;
    @ManyToOne(fetch = FetchType.LAZY, optional = false) @JoinColumn(name = "user_id") private User user;
    @Column(nullable = false, length = 120) private String name;
    @Column(nullable = false, length = 20) private String accountType;
    @Column(nullable = false, length = 3) private String currencyCode;
    @Column(nullable = false, precision = 18, scale = 2) private BigDecimal openingBalance;
    @Column(nullable = false) private Boolean active;
    @Column(nullable = false) private LocalDateTime createdAt;
    @Column(nullable = false) private LocalDateTime updatedAt;
    @PrePersist void create() { var now=LocalDateTime.now(); createdAt=now; updatedAt=now; if(active==null)active=true; if(currencyCode==null)currencyCode="VND"; if(openingBalance==null)openingBalance=BigDecimal.ZERO; }
    @PreUpdate void update(){updatedAt=LocalDateTime.now();}
}
