package com.fittrack.focus;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;
public interface FocusOperationRepository extends JpaRepository<FocusOperation,String> {
 Optional<FocusOperation> findByOwnerIdAndOperationId(String ownerId,String operationId);
}
