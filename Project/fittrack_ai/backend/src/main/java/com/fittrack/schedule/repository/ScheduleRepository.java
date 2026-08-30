package com.fittrack.schedule.repository;

import com.fittrack.schedule.entity.ScheduleItem;
import com.fittrack.user.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface ScheduleRepository extends JpaRepository<ScheduleItem, String> {
    List<ScheduleItem> findByUserOrderByStartAtAsc(User user);
    List<ScheduleItem> findByUserAndEnabledTrueOrderByStartAtAsc(User user);
    List<ScheduleItem> findAllByEnabledTrueAndReminderEnabledTrue();
    Optional<ScheduleItem> findByIdAndUser(String id, User user);
}
