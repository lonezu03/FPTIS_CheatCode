package com.fittrack.focus;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import java.time.LocalDateTime;

@Entity @Table(name="focus_sessions") @Getter @Setter
public class FocusSession {
 @Id @GeneratedValue(strategy=GenerationType.UUID) private String id;
 @Column(nullable=false) private String ownerId;
 // Snapshot identity, deliberately no hard FK: deleting Todo must preserve focus history.
 private String todoId;
 @Column(nullable=false,length=180) private String title;
 @Column(nullable=false,length=30) private String category;
 @Column(nullable=false,length=10) private String mode;
 @Column(nullable=false,length=12) private String state;
 @Column(nullable=false) private int plannedSeconds;
 @Column(nullable=false) private int accumulatedSeconds;
 @Column(nullable=false) private LocalDateTime createdAt;
 private LocalDateTime runningSince;
 private LocalDateTime endedAt;
 @Column(nullable=false) private boolean reviewRequired;
 @Version private Long version;
}
