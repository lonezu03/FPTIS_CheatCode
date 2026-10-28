package com.fittrack.nutrition.pantry;
import com.fittrack.user.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.domain.*;
import java.util.Optional;
public interface PantryOperationRepository extends JpaRepository<PantryOperation,String> {
 Optional<PantryOperation> findByUserAndOperationId(User user,String operationId);
 Page<PantryOperation> findByBatchAndUserOrderByCreatedAtDesc(PantryBatch batch,User user,Pageable page);
}
