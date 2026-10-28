package com.fittrack.personaltracking;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import java.time.LocalDate;

@Entity @Table(name="habit_schedule_history",uniqueConstraints=@UniqueConstraint(columnNames={"entry_id","effective_from"})) @Getter @Setter
public class HabitSchedule {
 @Id @GeneratedValue(strategy=GenerationType.UUID) private String id;
 @Column(name="entry_id",nullable=false) private String entryId;
 @Column(name="effective_from",nullable=false) private LocalDate effectiveFrom;
 @Column(nullable=false,length=20) private String weekdays="";
}
