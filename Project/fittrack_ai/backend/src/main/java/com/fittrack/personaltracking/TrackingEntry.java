package com.fittrack.personaltracking;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import java.math.BigDecimal;
import java.time.*;

/** Private owner-scoped records, never a Todo, diary entry or medical diagnosis. */
@Entity @Table(name="personal_tracking_entries", indexes=@Index(name="idx_tracking_owner_kind",columnList="owner_id,kind,start_date"))
@Getter @Setter
public class TrackingEntry {
 @Id @GeneratedValue(strategy=GenerationType.UUID) private String id;
 @Column(name="owner_id",nullable=false) private String ownerId;
 @Column(nullable=false,length=20) private String kind;
 @Column(nullable=false,length=160) private String title;
 @Column(length=2000) private String note;
 @Column(length=40) private String metric;
 @Column(length=20) private String unit;
 @Column(precision=18,scale=3) private BigDecimal baseline;
 @Column(precision=18,scale=3) private BigDecimal target;
 private LocalDate startDate;
 private LocalDate targetDate;
 /** ISO weekdays 1..7; empty means every day. */
 @Column(length=20) private String weekdays;
 private LocalDateTime sleepStart;
 private LocalDateTime sleepEnd;
 private Integer quality;
 private Integer fatigue;
 private Integer soreness;
 @Column(nullable=false) private boolean archived;
 /** Marks child-only goal phase replacements dirty so @Version protects the aggregate. */
 @Column(nullable=false) private long contentRevision;
 @Version private Long version;
}
