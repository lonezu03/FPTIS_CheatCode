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
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class ScheduleServiceTest {
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

        assertThat(result).hasSize(4);
        assertThat(result).filteredOn(entry -> entry.sourceType().equals("TODO"))
                .singleElement().extracting(entry -> entry.sourceId()).isEqualTo("todo-1");
        assertThat(result).filteredOn(entry -> entry.sourceType().equals("EVENT")).hasSize(3);
    }
}
