package com.fittrack.focus;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
@Entity @Table(name="focus_operations",uniqueConstraints=@UniqueConstraint(columnNames={"owner_id","operation_id"})) @Getter @Setter
public class FocusOperation {
 @Id @GeneratedValue(strategy=GenerationType.UUID) private String id;
 @Column(nullable=false) private String ownerId;
 @Column(nullable=false,length=80) private String operationId;
 @Column(nullable=false,length=64) private String fingerprint;
 @Column(nullable=false,columnDefinition="text") private String resultJson;
}
