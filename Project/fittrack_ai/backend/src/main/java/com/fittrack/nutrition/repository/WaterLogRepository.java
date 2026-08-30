package com.fittrack.nutrition.repository;

import com.fittrack.nutrition.entity.WaterLog;
import com.fittrack.user.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

public interface WaterLogRepository extends JpaRepository<WaterLog, String> {
    List<WaterLog> findByUserAndLoggedAtBetweenOrderByLoggedAtDesc(
            User user,
            LocalDateTime from,
            LocalDateTime to
    );

    Optional<WaterLog> findByIdAndUser(String id, User user);
}
