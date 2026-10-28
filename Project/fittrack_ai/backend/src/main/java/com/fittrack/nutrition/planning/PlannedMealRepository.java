package com.fittrack.nutrition.planning;
import com.fittrack.user.entity.User;
import jakarta.persistence.LockModeType;
import org.springframework.data.domain.*;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;
import java.time.LocalDate;
import java.util.*;
public interface PlannedMealRepository extends JpaRepository<PlannedMeal,String> {
    Page<PlannedMeal> findByUserAndDateBetweenOrderByDateAscCreatedAtAsc(User user,LocalDate from,LocalDate to,Pageable pageable);
    List<PlannedMeal> findByUserAndDateBetweenOrderByDateAscCreatedAtAsc(User user,LocalDate from,LocalDate to);
    long countByUserAndDateBetween(User user,LocalDate from,LocalDate to);
    @Lock(LockModeType.PESSIMISTIC_WRITE) @Query("select m from PlannedMeal m where m.id=:id and m.user=:user")
    Optional<PlannedMeal> lock(@Param("id") String id,@Param("user") User user);
}
