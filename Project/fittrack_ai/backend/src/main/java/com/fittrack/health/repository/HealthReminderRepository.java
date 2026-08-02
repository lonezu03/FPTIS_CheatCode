package com.fittrack.health.repository;

import com.fittrack.health.entity.HealthReminder;
import com.fittrack.user.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.data.domain.Pageable;
import jakarta.persistence.LockModeType;
import java.time.LocalDateTime;

import java.util.List;
import java.util.Optional;

public interface HealthReminderRepository
        extends JpaRepository<HealthReminder, String> {

    List<HealthReminder> findByUserOrderByReminderTimeAsc(User user);

    List<HealthReminder> findByEnabledTrue();

    Optional<HealthReminder> findByIdAndUser(String id, User user);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("""
            select reminder from HealthReminder reminder
            join fetch reminder.user
            where reminder.enabled = true
              and (reminder.nextRunAt is null or reminder.nextRunAt <= :now)
            order by reminder.nextRunAt asc
            """)
    List<HealthReminder> findDueForUpdate(
            @Param("now") LocalDateTime now,
            Pageable pageable
    );
}
