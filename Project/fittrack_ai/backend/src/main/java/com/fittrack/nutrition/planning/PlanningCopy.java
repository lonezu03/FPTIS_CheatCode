package com.fittrack.nutrition.planning;
import com.fittrack.user.entity.User;
import jakarta.persistence.*;
import lombok.*;

@Entity @Table(name="nutrition_planning_copies",uniqueConstraints=@UniqueConstraint(columnNames={"user_id","operation_id"}))
@Getter @Setter @NoArgsConstructor
public class PlanningCopy {
    @Id @GeneratedValue(strategy=GenerationType.UUID) private String id;
    @ManyToOne(fetch=FetchType.LAZY,optional=false) @JoinColumn(name="user_id",nullable=false) private User user;
    @Column(name="operation_id",nullable=false,length=80) private String operationId;
    @Column(nullable=false,length=100) private String fingerprint;
    @Column(nullable=false) private int copiedCount;
}
