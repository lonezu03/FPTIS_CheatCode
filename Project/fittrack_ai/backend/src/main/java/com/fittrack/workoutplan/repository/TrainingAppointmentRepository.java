package com.fittrack.workoutplan.repository;
import com.fittrack.workoutplan.entity.TrainingAppointment;
import com.fittrack.user.entity.User;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;
import jakarta.persistence.LockModeType;
import java.time.*;
import java.util.*;
public interface TrainingAppointmentRepository extends JpaRepository<TrainingAppointment,String> {
 List<TrainingAppointment> findByUserAndStartAtGreaterThanEqualAndStartAtLessThanOrderByStartAtAsc(User user, LocalDateTime from,LocalDateTime to);
 List<TrainingAppointment> findByUserAndCycleIdOrderByStartAtAsc(User user,String cycleId);
 Optional<TrainingAppointment> findByIdAndUser(String id,User user);
 @Lock(LockModeType.PESSIMISTIC_WRITE)
 @Query("select a from TrainingAppointment a where a.id=:id and a.user=:user")
 Optional<TrainingAppointment> lockOwned(@Param("id") String id,@Param("user") User user);
}
