package com.fittrack.workoutplan.entity;
import com.fittrack.user.entity.User;
import jakarta.persistence.*;
import lombok.*;
import java.time.*;
@Entity @Table(name="training_cycles") @Getter @Setter @NoArgsConstructor
public class TrainingCycle {
 @Id @GeneratedValue(strategy=GenerationType.UUID) private String id;
 @ManyToOne(fetch=FetchType.LAZY) @JoinColumn(nullable=false) private User user;
 @Column(nullable=false,length=180) private String name;
 @Column(nullable=false) private LocalDate startDate;
 @Column(nullable=false,columnDefinition="text") private String weeksJson;
 @Version private Long version;
 @Column(nullable=false) private LocalDateTime createdAt=LocalDateTime.now();
}
