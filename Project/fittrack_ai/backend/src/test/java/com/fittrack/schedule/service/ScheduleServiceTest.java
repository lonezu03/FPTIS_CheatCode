package com.fittrack.schedule.service;

import com.fittrack.lunch.service.LunchNotificationService;
import com.fittrack.schedule.entity.ScheduleItem;
import com.fittrack.schedule.repository.ScheduleRepository;
import com.fittrack.todo.entity.Todo;
import com.fittrack.todo.repository.TodoRepository;
import com.fittrack.user.entity.User;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDateTime;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class ScheduleServiceTest {
    private static final ZoneId BUSINESS_ZONE = ZoneId.of("Asia/Ho_Chi_Minh");

    @Mock
    private ScheduleRepository scheduleRepository;
    @Mock
    private TodoRepository todoRepository;
    @Mock
    private LunchNotificationService notificationService;
    @InjectMocks
    private ScheduleService service;

    @Test
    void calendarCombinesTimedTodosAndExpandedEventsWithoutDuplicatingTodoAsSchedule() {
        User user = new User();
        user.setTodoEnabled(true);
        Todo todo = Todo.builder().id("todo-1").user(user).title("Viết báo cáo")
                .status(Todo.TodoStatus.OPEN).priority(Todo.TodoPriority.HIGH).category(Todo.TodoCategory.WORK)
                .recurrenceRule(Todo.RecurrenceRule.NONE).recurrenceInterval(1)
                .startAt(LocalDateTime.of(2026, 9, 2, 10, 0)).estimatedMinutes(60)
                .reminderEnabled(false).subtasks(List.of()).build();
        ScheduleItem event = ScheduleItem.builder().id("event-1").user(user).title("Học tiếng Nhật")
                .category(ScheduleItem.ScheduleCategory.STUDY)
                .startAt(LocalDateTime.of(2026, 9, 1, 21, 0))
                .endAt(LocalDateTime.of(2026, 9, 1, 21, 30))
                .repeatRule(ScheduleItem.RepeatRule.DAILY).repeatInterval(1)
                .reminderMinutes(10).reminderEnabled(true).enabled(true).build();
        when(todoRepository.findByUserOrderByDueAtAscCreatedAtDesc(user)).thenReturn(List.of(todo));
        when(scheduleRepository.findByUserAndEnabledTrueOrderByStartAtAsc(user)).thenReturn(List.of(event));

        var result = service.getCalendar(user,
                LocalDateTime.of(2026, 9, 1, 0, 0),
                LocalDateTime.of(2026, 9, 4, 0, 0));

        assertThat(result).hasSize(5);
        assertThat(result).filteredOn(entry -> entry.sourceType().equals("TODO"))
                .hasSize(2).allSatisfy(entry -> assertThat(entry.sourceId()).isEqualTo("todo-1"));
        assertThat(result).filteredOn(entry -> entry.sourceType().equals("EVENT")).hasSize(3);
    }

    @Test
    void unfinishedTodoCarriesIntoEachDayThroughTodayWithoutChangingItsStoredDate() {
        User user = new User();
        user.setTodoEnabled(true);
        LocalDate today = LocalDate.now(BUSINESS_ZONE);
        LocalDateTime originalStart = today.minusDays(2).atTime(9, 15);
        Todo todo = Todo.builder().id("todo-overdue").user(user).title("Hoàn thành báo cáo")
                .status(Todo.TodoStatus.OPEN).priority(Todo.TodoPriority.HIGH).category(Todo.TodoCategory.WORK)
                .recurrenceRule(Todo.RecurrenceRule.NONE).recurrenceInterval(1)
                .startAt(originalStart).estimatedMinutes(45)
                .reminderEnabled(false).subtasks(List.of()).build();
        when(todoRepository.findByUserOrderByDueAtAscCreatedAtDesc(user)).thenReturn(List.of(todo));
        when(scheduleRepository.findByUserAndEnabledTrueOrderByStartAtAsc(user)).thenReturn(List.of());

        var result = service.getCalendar(user, today.minusDays(2).atStartOfDay(), today.plusDays(1).atStartOfDay());

        assertThat(result).hasSize(3);
        assertThat(result).allSatisfy(entry -> {
            assertThat(entry.sourceType()).isEqualTo("TODO");
            assertThat(entry.status()).isEqualTo("OPEN");
            assertThat(entry.startAt().toLocalTime()).isEqualTo(originalStart.toLocalTime());
        });
        assertThat(result.getLast().startAt().toLocalDate()).isEqualTo(today);
        assertThat(todo.getStartAt()).isEqualTo(originalStart);
    }

    @Test
    void completedOverdueTodoHasFinalCrossableOccurrenceOnCompletionDayAndStopsThere() {
        User user = new User();
        user.setTodoEnabled(true);
        LocalDate today = LocalDate.now(BUSINESS_ZONE);
        Todo todo = Todo.builder().id("todo-done").user(user).title("Gửi hồ sơ")
                .status(Todo.TodoStatus.DONE).priority(Todo.TodoPriority.MEDIUM)
                .category(Todo.TodoCategory.PERSONAL).recurrenceRule(Todo.RecurrenceRule.NONE)
                .recurrenceInterval(1).dueAt(today.minusDays(2).atTime(17, 0))
                .completedAt(today.atTime(10, 30)).reminderEnabled(false).subtasks(List.of()).build();
        when(todoRepository.findByUserOrderByDueAtAscCreatedAtDesc(user)).thenReturn(List.of(todo));
        when(scheduleRepository.findByUserAndEnabledTrueOrderByStartAtAsc(user)).thenReturn(List.of());

        var result = service.getCalendar(user, today.minusDays(2).atStartOfDay(), today.plusDays(2).atStartOfDay());

        assertThat(result).hasSize(3);
        assertThat(result).allSatisfy(entry -> assertThat(entry.status()).isEqualTo("DONE"));
        assertThat(result.getLast().startAt().toLocalDate()).isEqualTo(today);
        assertThat(result).noneMatch(entry -> entry.startAt().toLocalDate().isAfter(today));
    }
}
