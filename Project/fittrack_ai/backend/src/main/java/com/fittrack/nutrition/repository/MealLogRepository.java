package com.fittrack.nutrition.repository;

import com.fittrack.nutrition.entity.MealLog;
import com.fittrack.user.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

public interface MealLogRepository extends JpaRepository<MealLog, String> {
    List<MealLog> findByUserAndLogDateOrderByCreatedAtDesc(User user, LocalDate logDate);

    List<MealLog> findByUserAndLogDate(User user, LocalDate logDate);

    List<MealLog> findByUserOrderByLogDateDesc(User user);

    List<MealLog> findByUserAndLogDateBetweenOrderByLogDateAsc(
            User user,
            LocalDate fromDate,
            LocalDate toDate
    );

    Optional<MealLog> findByIdAndUser(String id, User user);
}

