package com.fittrack.sharing;

import com.fittrack.user.entity.User;
import jakarta.persistence.LockModeType;
import org.springframework.data.domain.*;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;
import java.util.*;

public interface TemplateShareRepository extends JpaRepository<TemplateShare, String> {
    Optional<TemplateShare> findByOwnerAndOperationId(User owner, String operationId);
    Page<TemplateShare> findByOwnerAndKindInOrderByCreatedAtDesc(User owner, Collection<String> kinds, Pageable page);
    Page<TemplateShare> findByRecipientAndKindInOrderByCreatedAtDesc(User recipient, Collection<String> kinds, Pageable page);
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select s from TemplateShare s where s.id = :id")
    Optional<TemplateShare> locked(@Param("id") String id);
}
