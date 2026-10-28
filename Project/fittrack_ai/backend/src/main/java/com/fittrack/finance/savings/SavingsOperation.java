package com.fittrack.finance.savings;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import java.math.BigDecimal;
import java.time.LocalDateTime;
@Entity @Table(name="finance_savings_operations",uniqueConstraints=@UniqueConstraint(columnNames={"goal_id","operation_id"})) @Getter @Setter
public class SavingsOperation {
 @Id @GeneratedValue(strategy=GenerationType.UUID) private String id;
 @Column(name="goal_id",nullable=false) private String goalId;
 @Column(name="operation_id",nullable=false,length=80) private String operationId;
 @Column(nullable=false,length=10) private String type;
 @Column(nullable=false,precision=18,scale=2) private BigDecimal amount;
 @Column(nullable=false,length=3) private String currencyCode;
 @Column(length=1000) private String note;
 @Column(nullable=false) private LocalDateTime createdAt;
}
