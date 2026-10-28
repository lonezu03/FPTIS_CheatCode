package com.fittrack.nutrition.pantry;
import com.fittrack.user.entity.User;
import jakarta.persistence.LockModeType;
import org.springframework.data.domain.*;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;
import java.time.LocalDate;
import java.util.*;
public interface PantryRepository extends JpaRepository<PantryBatch,String> {
 @EntityGraph(attributePaths="food") Page<PantryBatch> findByUserAndActiveOrderByCreatedAtDesc(User user,boolean active,Pageable page);
 @EntityGraph(attributePaths="food") List<PantryBatch> findByUserAndActiveTrueAndQuantityGreaterThan(User user,java.math.BigDecimal zero);
 @Lock(LockModeType.PESSIMISTIC_WRITE) @Query("select b from PantryBatch b join fetch b.food where b.id=:id and b.user=:user")
 Optional<PantryBatch> lock(@Param("id")String id,@Param("user")User user);
 @EntityGraph(attributePaths={"food","user"})
 @Query("select b from PantryBatch b where b.active=true and b.quantity>0 and b.expiresOn between :from and :to order by b.id")
 Page<PantryBatch> expiring(@Param("from")LocalDate from,@Param("to")LocalDate to,Pageable page);
}
