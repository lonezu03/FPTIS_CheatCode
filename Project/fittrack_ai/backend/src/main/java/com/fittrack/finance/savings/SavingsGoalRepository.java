package com.fittrack.finance.savings;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.domain.*;
import jakarta.persistence.LockModeType;
import java.util.Optional;
public interface SavingsGoalRepository extends JpaRepository<SavingsGoal,String>{
 Page<SavingsGoal> findByOwnerIdAndArchivedOrderByTargetDateAsc(String owner,boolean archived,Pageable page);
 @Lock(LockModeType.PESSIMISTIC_WRITE) @Query("select g from SavingsGoal g where g.id=:id and g.ownerId=:owner") Optional<SavingsGoal> lock(String id,String owner);
 Optional<SavingsGoal> findByIdAndOwnerId(String id,String owner);
}
