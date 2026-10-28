package com.fittrack.workout.repository;
import com.fittrack.workout.entity.WorkoutSet;
import org.springframework.data.jpa.repository.*;
import java.time.LocalDate;
import java.util.List;
public interface TrainingComparisonRepository extends JpaRepository<WorkoutSet,String> {
 @Query("select s from WorkoutSet s join fetch s.session w join fetch s.exercise e where w.user.id=:owner and w.sessionDate between :from and :to and s.completed=true and s.setType<>com.fittrack.workout.entity.WorkoutSetType.WARMUP and (:plan='' or exists(select a.id from TrainingAppointment a where a.user.id=:owner and a.planId=:plan and a.startAt>=:start and a.startAt<:end and a.completedSessionId=w.id)) order by w.sessionDate,w.id")
 List<WorkoutSet> sets(String owner,LocalDate from,LocalDate to,String plan,java.time.LocalDateTime start,java.time.LocalDateTime end,org.springframework.data.domain.Pageable page);
 @Query("select count(a) from TrainingAppointment a where a.user.id=:owner and a.planId=:plan and a.startAt>=:from and a.startAt<:to")
 long planned(String owner,String plan,java.time.LocalDateTime from,java.time.LocalDateTime to);
}
