package com.fittrack.nutrition.pantry;
import com.fittrack.user.entity.User;
import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.*;
@Entity @Table(name="pantry_operations") @Getter @Setter
public class PantryOperation {
 @Id @GeneratedValue(strategy=GenerationType.UUID) private String id;
 @ManyToOne(fetch=FetchType.LAZY,optional=false) @JoinColumn(name="batch_id") private PantryBatch batch;
 @ManyToOne(fetch=FetchType.LAZY,optional=false) @JoinColumn(name="user_id") private User user;
 @Column(nullable=false,length=80) private String operationId;
 @Column(nullable=false,length=64) private String fingerprint;
 @Column(nullable=false,length=20) private String type;
 @Column(nullable=false,precision=18,scale=3) private BigDecimal amount;
 @Column(nullable=false,precision=18,scale=3) private BigDecimal balanceAfter;
 @Column(length=1000) private String note;
 @Column(nullable=false) private LocalDateTime createdAt=LocalDateTime.now(ZoneId.of("Asia/Ho_Chi_Minh"));
}
