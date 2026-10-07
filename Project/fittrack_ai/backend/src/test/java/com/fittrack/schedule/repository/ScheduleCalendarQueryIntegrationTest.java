package com.fittrack.schedule.repository;

import com.fittrack.FittrackBackendApplication;
import com.fittrack.schedule.entity.ScheduleItem;
import com.fittrack.todo.entity.Todo;
import com.fittrack.todo.repository.TodoRepository;
import com.fittrack.user.entity.User;
import com.fittrack.user.repository.UserRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest(classes = FittrackBackendApplication.class)
@ActiveProfiles("test")
@Transactional
class ScheduleCalendarQueryIntegrationTest {
    @Autowired private UserRepository users;
    @Autowired private ScheduleRepository schedules;
    @Autowired private TodoRepository todos;

    @Test
    void boundedQueriesKeepCarryOverAndRecurringItemsWithoutOldOneOffRows() {
        User owner = users.save(User.builder()
                .email("calendar-" + UUID.randomUUID() + "@example.test")
                .password("encoded").build());
        User other = users.save(User.builder()
                .email("other-" + UUID.randomUUID() + "@example.test")
                .password("encoded").build());
        LocalDateTime from = LocalDateTime.of(2026, 10, 5, 0, 0);
        LocalDateTime to = from.plusDays(3);

        schedules.save(schedule(owner, "old", from.minusYears(2), ScheduleItem.RepeatRule.NONE));
        schedules.save(schedule(owner, "recurring", from.minusYears(2), ScheduleItem.RepeatRule.DAILY));
        schedules.save(schedule(other, "other", from.plusDays(1), ScheduleItem.RepeatRule.NONE));
        schedules.flush();

        todos.save(todo(owner, "carry", from.minusMonths(2), Todo.TodoStatus.OPEN, null));
        todos.save(todo(owner, "done-in-window", from.minusMonths(2), Todo.TodoStatus.DONE, from.plusDays(1)));
        todos.save(todo(owner, "old-done", from.minusMonths(2), Todo.TodoStatus.DONE, from.minusMonths(1)));
        todos.save(todo(other, "other", from.plusDays(1), Todo.TodoStatus.OPEN, null));
        todos.flush();

        assertThat(schedules.findCalendarCandidates(owner, from, to, ScheduleItem.RepeatRule.NONE))
                .extracting(ScheduleItem::getTitle).containsExactly("recurring");
        assertThat(todos.findCalendarCandidates(owner, from, to, from, true,
                List.of(Todo.TodoStatus.OPEN, Todo.TodoStatus.IN_PROGRESS), Todo.TodoStatus.DONE))
                .extracting(Todo::getTitle).containsExactlyInAnyOrder("carry", "done-in-window");
    }

    private ScheduleItem schedule(User user, String title, LocalDateTime start,
                                  ScheduleItem.RepeatRule rule) {
        return ScheduleItem.builder().user(user).title(title).startAt(start)
                .repeatRule(rule).repeatInterval(1).enabled(true).reminderEnabled(false).build();
    }

    private Todo todo(User user, String title, LocalDateTime start,
                      Todo.TodoStatus status, LocalDateTime completedAt) {
        return Todo.builder().user(user).title(title).startAt(start)
                .status(status).completedAt(completedAt).build();
    }
}
