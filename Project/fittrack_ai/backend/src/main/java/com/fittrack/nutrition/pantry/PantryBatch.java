package com.fittrack.nutrition.pantry;
import com.fittrack.user.entity.User;
import com.fittrack.nutrition.entity.Food;
import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.*;
@Entity @Table(name="pantry_batches") @Getter @Setter
public class PantryBatch {
 @Id @GeneratedValue(strategy=GenerationType.UUID) private String id;
 @ManyToOne(fetch=FetchType.LAZY,optional=false) @JoinColumn(name="user_id") private User user;
 @ManyToOne(fetch=FetchType.LAZY,optional=false) @JoinColumn(name="food_id") private Food food;
 @Column(nullable=false,length=120) private String location;
 @Column(nullable=false,length=20) private String unit;
 @Column(nullable=false,precision=18,scale=3) private BigDecimal quantity;
 private LocalDate expiresOn;
 @Column(length=1000) private String note;
 @Column(nullable=false) private boolean active=true;
 @Version private long version;
 @Column(nullable=false) private LocalDateTime createdAt=LocalDateTime.now(ZoneId.of("Asia/Ho_Chi_Minh"));
}
