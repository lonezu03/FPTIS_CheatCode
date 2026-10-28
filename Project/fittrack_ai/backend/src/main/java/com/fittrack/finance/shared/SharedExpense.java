package com.fittrack.finance.shared;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import java.math.BigDecimal;
import java.time.*;
@Entity @Table(name="shared_expenses") @Getter @Setter
public class SharedExpense {
 @Id @GeneratedValue(strategy=GenerationType.UUID) private String id;
 @Column(nullable=false) private String groupId;
 @Column(nullable=false) private String creatorId;
 @Column(nullable=false) private String payerId;
 @Column(nullable=false,length=180) private String title;
 @Column(nullable=false,precision=16,scale=0) private BigDecimal amount;
 @Column(nullable=false) private LocalDate spentOn;
 @Column(nullable=false,columnDefinition="text") private String splits;
 @Column(nullable=false) private boolean voided;
 @Column(length=1000) private String note;
 @Column(nullable=false) private LocalDateTime createdAt;
 @Version private Long version;
}
