package com.fittrack.todo.repository;

import com.fittrack.todo.entity.TodoReminderEntry;
import jakarta.persistence.LockModeType;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.List;

public interface TodoReminderEntryRepository extends JpaRepository<TodoReminderEntry, String> {
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("""
            select reminder from TodoReminderEntry reminder
            join fetch reminder.todo todo
            join fetch todo.user
            where reminder.sentAt is null and reminder.scheduledAt <= :now
            order by reminder.scheduledAt asc
            """)
    List<TodoReminderEntry> findDueForUpdate(@Param("now") LocalDateTime now, Pageable pageable);
}
