package com.fittrack.personaltracking;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import java.math.BigDecimal;
import java.time.LocalDate;
@Entity @Table(name="personal_tracking_checkins",uniqueConstraints=@UniqueConstraint(columnNames={"entry_id","checkin_date"}))
@Getter @Setter
public class TrackingCheckin {
 @Id @GeneratedValue(strategy=GenerationType.UUID) private String id;
 @Column(name="entry_id",nullable=false) private String entryId;
 @Column(name="checkin_date",nullable=false) private LocalDate day;
 @Column(nullable=false,length=12) private String status;
 @Column(name="metric_value",precision=18,scale=3) private BigDecimal value;
 @Column(length=1000) private String note;
 @Column(length=500) private String evidence;
}
