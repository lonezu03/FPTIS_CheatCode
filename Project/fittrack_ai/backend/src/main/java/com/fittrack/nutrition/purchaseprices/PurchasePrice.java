package com.fittrack.nutrition.purchaseprices;
import com.fittrack.user.entity.User;
import com.fittrack.nutrition.entity.Food;
import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.*;
@Entity @Table(name="food_purchase_prices") @Getter @Setter
public class PurchasePrice {
 @Id @GeneratedValue(strategy=GenerationType.UUID) private String id;
 @ManyToOne(fetch=FetchType.LAZY,optional=false) @JoinColumn(name="user_id") private User user;
 @ManyToOne(fetch=FetchType.LAZY,optional=false) @JoinColumn(name="food_id") private Food food;
 @Column(nullable=false,precision=18,scale=3) private BigDecimal amount;
 @Column(nullable=false,length=20) private String unit;
 @Column(nullable=false,precision=18,scale=0) private BigDecimal totalPrice;
 @Column(nullable=false) private LocalDate purchasedOn;
 @Column(length=160) private String store;
 @Column(length=1000) private String note;
 @Column(nullable=false) private boolean active=true;
 @Column(nullable=false,length=80) private String operationId;
 @Column(nullable=false,length=64) private String fingerprint;
 @Version private long version;
 @Column(nullable=false) private LocalDateTime createdAt=LocalDateTime.now(ZoneId.of("Asia/Ho_Chi_Minh"));
}
