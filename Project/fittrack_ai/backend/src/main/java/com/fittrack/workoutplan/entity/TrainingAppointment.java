package com.fittrack.workoutplan.entity;
import com.fittrack.user.entity.User;
import jakarta.persistence.*;
import lombok.*;
import java.time.*;
@Entity @Table(name="training_appointments") @Getter @Setter @NoArgsConstructor
public class TrainingAppointment {
 @Id @GeneratedValue(strategy=GenerationType.UUID) private String id;
 @ManyToOne(fetch=FetchType.LAZY) @JoinColumn(nullable=false) private User user;
 @Column(nullable=false,length=255) private String title;
 private String planId;
 private String cycleId;
 private Integer weekNumber;
 @Column(nullable=false) private LocalDateTime startAt;
 @Column(nullable=false,columnDefinition="text") private String snapshotJson;
 @Column(length=255) private String completedSessionId;
 private LocalDateTime completedAt;
 @Version private Long version;
 @Column(nullable=false) private LocalDateTime createdAt=LocalDateTime.now();
}
