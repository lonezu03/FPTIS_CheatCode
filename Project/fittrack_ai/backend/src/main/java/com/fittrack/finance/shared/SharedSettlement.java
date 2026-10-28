package com.fittrack.finance.shared;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import java.math.BigDecimal;
import java.time.LocalDateTime;
@Entity @Table(name="shared_expense_settlements") @Getter @Setter
public class SharedSettlement {
 @Id @GeneratedValue(strategy=GenerationType.UUID) private String id;
 @Column(nullable=false) private String groupId;
 @Column(nullable=false) private String initiatorId;
 @Column(nullable=false) private String debtorId;
 @Column(nullable=false) private String creditorId;
 @Column(nullable=false,precision=16,scale=0) private BigDecimal amount;
 @Column(nullable=false,length=16) private String status;
 @Column(length=1000) private String note;
 @Column(nullable=false) private LocalDateTime createdAt;
 private LocalDateTime resolvedAt;
 @Version private Long version;
}
