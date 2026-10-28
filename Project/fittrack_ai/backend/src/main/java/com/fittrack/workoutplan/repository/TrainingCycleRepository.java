package com.fittrack.workoutplan.repository;
import com.fittrack.workoutplan.entity.TrainingCycle;
import com.fittrack.user.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.domain.*;
import java.util.*;
public interface TrainingCycleRepository extends JpaRepository<TrainingCycle,String> {
 Optional<TrainingCycle> findByIdAndUser(String id, User user);
 Page<TrainingCycle> findByUserOrderByStartDateDesc(User user,Pageable pageable);
}
