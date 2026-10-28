package com.fittrack.focus;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.domain.*;
import org.springframework.data.repository.query.Param;
import jakarta.persistence.LockModeType;
import java.util.*;
import java.time.LocalDateTime;
public interface FocusRepository extends JpaRepository<FocusSession,String> {
 Optional<FocusSession> findFirstByOwnerIdAndStateInOrderByCreatedAtDesc(String ownerId,Collection<String> states);
 Optional<FocusSession> findByIdAndOwnerId(String id,String ownerId);
 @Lock(LockModeType.PESSIMISTIC_WRITE) @Query("select s from FocusSession s where s.id=:id and s.ownerId=:owner")
 Optional<FocusSession> locked(@Param("id")String id,@Param("owner")String owner);
 Page<FocusSession> findByOwnerIdAndCreatedAtGreaterThanEqualAndCreatedAtLessThanOrderByCreatedAtDescIdDesc(String owner,LocalDateTime from,LocalDateTime to,Pageable page);
}
