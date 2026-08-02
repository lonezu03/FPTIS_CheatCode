package com.fittrack.nutrition.repository;

import com.fittrack.nutrition.entity.MealLog;
import com.fittrack.user.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

public interface MealLogRepository extends JpaRepository<MealLog, String> {
    List<MealLog> findByUserAndLogDateOrderByCreatedAtDesc(User user, LocalDate logDate);

    Page<MealLog> findByUserAndLogDateOrderByCreatedAtDesc(
            User user,
            LocalDate logDate,
            Pageable pageable
    );

    List<MealLog> findByUserAndLogDate(User user, LocalDate logDate);

    List<MealLog> findByUserOrderByLogDateDesc(User user);

    Page<MealLog> findByUserOrderByLogDateDescCreatedAtDesc(
            User user,
            Pageable pageable
    );

    List<MealLog> findByUserAndLogDateBetweenOrderByLogDateAsc(
            User user,
            LocalDate fromDate,
            LocalDate toDate
    );

    Optional<MealLog> findByIdAndUser(String id, User user);

    Optional<MealLog> findBySourceLunchOrderId(String sourceLunchOrderId);
}

