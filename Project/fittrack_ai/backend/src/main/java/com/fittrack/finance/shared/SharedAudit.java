package com.fittrack.finance.shared;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import java.time.LocalDateTime;
/** Append-only operation receipt. No application update/delete endpoint exists. */
@Entity @Table(name="shared_expense_audit",uniqueConstraints=@UniqueConstraint(columnNames={"actor_id","operation_id"})) @Getter @Setter
public class SharedAudit {
 @Id @GeneratedValue(strategy=GenerationType.UUID) private String id;
 @Column(nullable=false) private String groupId;
 @Column(nullable=false) private String actorId;
 @Column(nullable=false,length=80) private String operationId;
 @Column(nullable=false,length=64) private String digest;
 @Column(nullable=false,length=40) private String action;
 @Column(nullable=false,columnDefinition="text") private String detail;
 @Column(nullable=false,columnDefinition="text") private String result;
 @Column(nullable=false) private LocalDateTime createdAt;
}
