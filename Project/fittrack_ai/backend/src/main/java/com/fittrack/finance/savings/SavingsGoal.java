package com.fittrack.finance.savings;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import java.time.LocalDate;
import java.math.BigDecimal;
@Entity @Table(name="finance_savings_goals",indexes=@Index(name="idx_savings_owner",columnList="owner_id")) @Getter @Setter
public class SavingsGoal {
 @Id @GeneratedValue(strategy=GenerationType.UUID) private String id;
 @Column(name="owner_id",nullable=false) private String ownerId;
 @Column(nullable=false,length=160) private String title;
 @Column(nullable=false,precision=18,scale=2) private BigDecimal target;
 @Column(nullable=false,precision=18,scale=2) private BigDecimal progress;
 @Column(nullable=false,length=3) private String currencyCode;
 private LocalDate targetDate;
 @Column(length=1000) private String note;
 @Column(nullable=false) private boolean archived;
 @Version private Long version;
}
