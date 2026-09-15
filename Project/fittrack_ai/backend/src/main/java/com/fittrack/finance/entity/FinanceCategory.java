package com.fittrack.finance.entity;

import com.fittrack.user.entity.User;
import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity @Table(name = "finance_categories")
@Getter @Setter @Builder @NoArgsConstructor @AllArgsConstructor
public class FinanceCategory {
    @Id @GeneratedValue(strategy = GenerationType.UUID) private String id;
    @ManyToOne(fetch = FetchType.LAZY, optional = false) @JoinColumn(name = "user_id") private User user;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "parent_id") private FinanceCategory parent;
    @Column(nullable = false, length = 120) private String name;
    @Column(nullable = false, length = 20) private String transactionKind;
    @Column(length = 30) private String expenseNature;
    @Column(length = 40) private String icon;
    @Column(nullable = false) private Boolean active;
    @Column(nullable = false) private Boolean systemCategory;
    @Column(nullable = false) private LocalDateTime createdAt;
    @Column(nullable = false) private LocalDateTime updatedAt;
    @PrePersist void create(){var now=LocalDateTime.now();createdAt=now;updatedAt=now;if(active==null)active=true;if(systemCategory==null)systemCategory=false;}
    @PreUpdate void update(){updatedAt=LocalDateTime.now();}
}
