package com.fittrack.finance.savings;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.domain.*;
import java.util.Optional;
public interface SavingsOperationRepository extends JpaRepository<SavingsOperation,String>{
 Optional<SavingsOperation> findByGoalIdAndOperationId(String goal,String operation);
 Page<SavingsOperation> findByGoalIdOrderByCreatedAtDesc(String goal,Pageable page);
}
