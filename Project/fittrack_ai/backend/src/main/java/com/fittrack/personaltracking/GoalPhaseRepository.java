package com.fittrack.personaltracking;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
public interface GoalPhaseRepository extends JpaRepository<GoalPhase,String> {
 List<GoalPhase> findByGoalIdOrderByPositionAsc(String goal);
 void deleteByGoalId(String goal);
}
