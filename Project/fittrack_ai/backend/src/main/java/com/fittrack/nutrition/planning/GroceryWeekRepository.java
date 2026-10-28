package com.fittrack.nutrition.planning;
import com.fittrack.user.entity.User;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;
import java.time.LocalDate;
import java.util.*;
public interface GroceryWeekRepository extends JpaRepository<GroceryWeek,String> {
    Optional<GroceryWeek> findByUserAndWeek(User user,LocalDate week);
    @Lock(LockModeType.PESSIMISTIC_WRITE) @Query("select g from GroceryWeek g where g.user=:user and g.week=:week")
    Optional<GroceryWeek> lock(@Param("user") User user,@Param("week") LocalDate week);
}
