package com.fittrack.recommendation.repository;

import com.fittrack.recommendation.entity.WeeklyCheckIn;
import com.fittrack.user.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

public interface WeeklyCheckInRepository extends JpaRepository<WeeklyCheckIn, String> {
    Optional<WeeklyCheckIn> findByUserAndWeekStart(User user, LocalDate weekStart);
    List<WeeklyCheckIn> findByUserOrderByWeekStartDesc(User user);
    Optional<WeeklyCheckIn> findByIdAndUser(String id, User user);
}
