package com.fittrack.finance.shared;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import java.time.LocalDateTime;
@Entity @Table(name="shared_expense_members",uniqueConstraints=@UniqueConstraint(columnNames={"group_id","user_id"})) @Getter @Setter
public class SharedMember {
 @Id @GeneratedValue(strategy=GenerationType.UUID) private String id;
 @Column(nullable=false) private String groupId;
 @Column(nullable=false) private String userId;
 @Column(nullable=false,length=160) private String displayName;
 @Column(nullable=false,length=16) private String status;
 @Column(nullable=false) private LocalDateTime invitedAt;
 private LocalDateTime acceptedAt;
}
