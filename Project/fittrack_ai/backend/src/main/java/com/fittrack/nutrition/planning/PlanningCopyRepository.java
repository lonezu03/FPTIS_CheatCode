package com.fittrack.nutrition.planning;
import com.fittrack.user.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;
public interface PlanningCopyRepository extends JpaRepository<PlanningCopy,String> {
    Optional<PlanningCopy> findByUserAndOperationId(User user,String operationId);
}
