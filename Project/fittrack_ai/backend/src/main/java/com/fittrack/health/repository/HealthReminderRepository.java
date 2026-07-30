package com.fittrack.health.repository;

import com.fittrack.health.entity.HealthReminder;
import com.fittrack.user.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface HealthReminderRepository
        extends JpaRepository<HealthReminder, String> {

    List<HealthReminder> findByUserOrderByReminderTimeAsc(User user);

    List<HealthReminder> findByEnabledTrue();

    Optional<HealthReminder> findByIdAndUser(String id, User user);
}
