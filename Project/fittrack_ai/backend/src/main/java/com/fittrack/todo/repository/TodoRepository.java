package com.fittrack.todo.repository;

import com.fittrack.todo.entity.Todo;
import com.fittrack.user.entity.User;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import jakarta.persistence.LockModeType;

import java.util.List;
import java.util.Optional;

public interface TodoRepository extends JpaRepository<Todo, String> {
    List<Todo> findByUserAndStatusNotOrderByDueAtAscCreatedAtDesc(User user, Todo.TodoStatus status);
    List<Todo> findByUserOrderByDueAtAscCreatedAtDesc(User user);
    Optional<Todo> findByIdAndUser(String id, User user);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("""
            select t from Todo t
            where t.reminderEnabled = true
              and t.reminderAt is not null
              and t.reminderAt <= :now
              and t.reminderSentAt is null
            order by t.reminderAt asc
            """)
    List<Todo> findDueRemindersForUpdate(@Param("now") java.time.LocalDateTime now, Pageable pageable);

    List<Todo> findByRecurringSeriesIdAndUserOrderByDueAtAsc(String recurringSeriesId, User user);
}
