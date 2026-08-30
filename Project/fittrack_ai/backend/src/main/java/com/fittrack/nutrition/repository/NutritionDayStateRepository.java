package com.fittrack.nutrition.repository;

import com.fittrack.nutrition.entity.NutritionDayState;
import com.fittrack.user.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

public interface NutritionDayStateRepository extends JpaRepository<NutritionDayState, String> {
    Optional<NutritionDayState> findByUserAndLogDate(User user, LocalDate logDate);

    List<NutritionDayState> findByUserAndLogDateBetween(
            User user,
            LocalDate fromDate,
            LocalDate toDate
    );
}
