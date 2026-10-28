package com.fittrack.personaltracking;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import java.math.BigDecimal;
import java.time.LocalDate;
@Entity @Table(name="personal_goal_phases") @Getter @Setter
public class GoalPhase {
 @Id @GeneratedValue(strategy=GenerationType.UUID) private String id;
 @Column(nullable=false) private String goalId;
 @Column(nullable=false,length=120) private String title;
 private LocalDate targetDate;
 @Column(nullable=false,precision=18,scale=3) private BigDecimal target;
 @Column(nullable=false) private int position;
}
