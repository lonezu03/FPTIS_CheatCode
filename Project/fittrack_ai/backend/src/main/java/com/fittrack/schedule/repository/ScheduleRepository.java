package com.fittrack.schedule.repository;

import com.fittrack.schedule.entity.ScheduleItem;
import com.fittrack.user.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;

import java.util.List;
import java.util.Optional;

public interface ScheduleRepository extends JpaRepository<ScheduleItem, String> {
    List<ScheduleItem> findByUserOrderByStartAtAsc(User user);
    List<ScheduleItem> findByUserAndEnabledTrueOrderByStartAtAsc(User user);
    @Query("""
            select s from ScheduleItem s
            where s.user = :user and s.enabled = true and s.startAt < :to
              and ((s.repeatRule = :none and s.startAt >= :from)
                or (s.repeatRule <> :none and (s.repeatEndAt is null or s.repeatEndAt >= :from)))
            order by s.startAt asc
            """)
    List<ScheduleItem> findCalendarCandidates(@Param("user") User user,
                                              @Param("from") LocalDateTime from,
                                              @Param("to") LocalDateTime to,
                                              @Param("none") ScheduleItem.RepeatRule none);
    List<ScheduleItem> findAllByEnabledTrueAndReminderEnabledTrue();
    @Query("""
            select s from ScheduleItem s
            where s.enabled = true and s.reminderEnabled = true and s.startAt < :to
              and ((s.repeatRule = :none and s.startAt >= :from)
                or (s.repeatRule <> :none and (s.repeatEndAt is null or s.repeatEndAt >= :from)))
            """)
    List<ScheduleItem> findReminderCandidates(@Param("from") LocalDateTime from,
                                              @Param("to") LocalDateTime to,
                                              @Param("none") ScheduleItem.RepeatRule none);
    Optional<ScheduleItem> findByIdAndUser(String id, User user);
}
