package com.fittrack.todo.service;

import com.fittrack.lunch.service.LunchNotificationService;
import com.fittrack.todo.dto.TodoDtos.SubtaskRequest;
import com.fittrack.todo.dto.TodoDtos.TodoRequest;
import com.fittrack.todo.entity.Todo;
import com.fittrack.todo.repository.TodoRepository;
import com.fittrack.user.entity.User;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class TodoServiceTest {
    private static final ZoneId ZONE = ZoneId.of("Asia/Ho_Chi_Minh");

    @Mock
    private TodoRepository repository;

    @Mock
    private LunchNotificationService notificationService;

    @InjectMocks
    private TodoService service;

    @Test
    void createStoresPlannerFieldsAndChecklist() {
        User user = new User();
        TodoRequest request = new TodoRequest(
                " Học tiếng Nhật ",
                "Ôn bài 12",
                Todo.TodoStatus.OPEN,
                Todo.TodoPriority.HIGH,
                LocalDateTime.of(2026, 8, 30, 20, 30),
                LocalDateTime.of(2026, 8, 30, 21, 30),
                45,
                Todo.TodoCategory.STUDY,
                Todo.RecurrenceRule.WEEKLY,
                1,
                "MONDAY,WEDNESDAY,FRIDAY",
                LocalDateTime.of(2026, 8, 30, 20, 0),
                true,
                List.of(new SubtaskRequest(null, "Ôn bài 12", false, 0))
        );
        when(repository.save(any(Todo.class))).thenAnswer(invocation -> invocation.getArgument(0));

        var response = service.create(user, request);

        ArgumentCaptor<Todo> captor = ArgumentCaptor.forClass(Todo.class);
        verify(repository).save(captor.capture());
        Todo saved = captor.getValue();
        assertThat(saved.getTitle()).isEqualTo("Học tiếng Nhật");
        assertThat(saved.getCategory()).isEqualTo(Todo.TodoCategory.STUDY);
        assertThat(saved.getEstimatedMinutes()).isEqualTo(45);
        assertThat(saved.getRecurringSeriesId()).isNotBlank();
        assertThat(saved.getSubtasks()).hasSize(1);
        assertThat(response.subtasks()).singleElement().extracting(item -> item.title()).isEqualTo("Ôn bài 12");
    }

    @Test
    void overdueViewExcludesCompletedTaskAndKeepsOpenTask() {
        User user = new User();
        LocalDate today = LocalDate.now(ZONE);
        Todo overdue = Todo.builder().user(user).title("Việc trễ").status(Todo.TodoStatus.OPEN)
                .priority(Todo.TodoPriority.MEDIUM).category(Todo.TodoCategory.WORK)
                .recurrenceRule(Todo.RecurrenceRule.NONE).recurrenceInterval(1)
                .dueAt(today.minusDays(1).atTime(17, 0)).reminderEnabled(false).subtasks(List.of()).build();
        Todo completed = Todo.builder().user(user).title("Đã xong").status(Todo.TodoStatus.DONE)
                .priority(Todo.TodoPriority.MEDIUM).category(Todo.TodoCategory.WORK)
                .recurrenceRule(Todo.RecurrenceRule.NONE).recurrenceInterval(1)
                .dueAt(today.minusDays(1).atTime(18, 0)).reminderEnabled(false).subtasks(List.of()).build();
        when(repository.findByUserOrderByDueAtAscCreatedAtDesc(user)).thenReturn(List.of(overdue, completed));

        var result = service.getMine(user, "OVERDUE", null, null);

        assertThat(result).hasSize(1);
        assertThat(result.getFirst().title()).isEqualTo("Việc trễ");
    }

    @Test
    void completingRecurringTodoCreatesNextOccurrence() {
        User user = new User();
        Todo todo = Todo.builder().id("todo-1").user(user).title("Tập thể dục")
                .status(Todo.TodoStatus.OPEN).priority(Todo.TodoPriority.HIGH).category(Todo.TodoCategory.HEALTH)
                .recurrenceRule(Todo.RecurrenceRule.DAILY).recurrenceInterval(1)
                .recurringSeriesId("series-1").dueAt(LocalDateTime.of(2026, 8, 30, 21, 0))
                .reminderEnabled(false).subtasks(List.of()).build();
        when(repository.findByIdAndUser("todo-1", user)).thenReturn(Optional.of(todo));
        when(repository.save(any(Todo.class))).thenAnswer(invocation -> invocation.getArgument(0));
        TodoRequest request = new TodoRequest(
                todo.getTitle(), null, Todo.TodoStatus.DONE, todo.getPriority(), todo.getDueAt().minusHours(1),
                todo.getDueAt(), todo.getEstimatedMinutes(), todo.getCategory(), todo.getRecurrenceRule(),
                todo.getRecurrenceInterval(), todo.getDaysOfWeek(), null, false, List.of()
        );

        service.update(user, "todo-1", request);

        ArgumentCaptor<Todo> captor = ArgumentCaptor.forClass(Todo.class);
        verify(repository, times(2)).save(captor.capture());
        Todo next = captor.getAllValues().get(1);
        assertThat(next.getStatus()).isEqualTo(Todo.TodoStatus.OPEN);
        assertThat(next.getDueAt()).isEqualTo(LocalDateTime.of(2026, 8, 31, 21, 0));
        assertThat(next.getRecurringSeriesId()).isEqualTo("series-1");
    }

    @Test
    void completionBasedRecurrenceUsesActualCompletionDate() {
        User user = new User();
        LocalDateTime oldDue = LocalDateTime.now(ZONE).minusDays(10).withHour(8).withMinute(30).withSecond(0).withNano(0);
        Todo todo = Todo.builder().id("todo-completion").user(user).title("Quét nhà")
                .status(Todo.TodoStatus.OPEN).priority(Todo.TodoPriority.MEDIUM).category(Todo.TodoCategory.PERSONAL)
                .recurrenceRule(Todo.RecurrenceRule.DAILY).recurrenceInterval(3)
                .recurrenceBasis(Todo.RecurrenceBasis.COMPLETION_DATE).occurrenceNumber(1)
                .recurringSeriesId("series-completion").dueAt(oldDue)
                .reminderEnabled(false).subtasks(List.of()).build();
        when(repository.findByIdAndUser("todo-completion", user)).thenReturn(Optional.of(todo));
        when(repository.save(any(Todo.class))).thenAnswer(invocation -> invocation.getArgument(0));

        service.complete(user, "todo-completion");

        ArgumentCaptor<Todo> captor = ArgumentCaptor.forClass(Todo.class);
        verify(repository, times(2)).save(captor.capture());
        Todo next = captor.getAllValues().get(1);
        assertThat(next.getDueAt().toLocalDate()).isEqualTo(LocalDate.now(ZONE).plusDays(3));
        assertThat(next.getDueAt().toLocalTime()).isEqualTo(oldDue.toLocalTime());
        assertThat(next.getOccurrenceNumber()).isEqualTo(2);
    }

    @Test
    void skippingRecurringTodoPreservesScheduledCadence() {
        User user = new User();
        LocalDateTime due = LocalDateTime.of(2026, 9, 1, 21, 0);
        Todo todo = Todo.builder().id("todo-skip").user(user).title("Học tiếng Nhật")
                .status(Todo.TodoStatus.OPEN).priority(Todo.TodoPriority.MEDIUM).category(Todo.TodoCategory.STUDY)
                .recurrenceRule(Todo.RecurrenceRule.WEEKLY).recurrenceInterval(1)
                .recurrenceBasis(Todo.RecurrenceBasis.COMPLETION_DATE).occurrenceNumber(4)
                .recurringSeriesId("series-skip").dueAt(due)
                .reminderEnabled(false).subtasks(List.of()).build();
        when(repository.findByIdAndUser("todo-skip", user)).thenReturn(Optional.of(todo));
        when(repository.save(any(Todo.class))).thenAnswer(invocation -> invocation.getArgument(0));

        service.skip(user, "todo-skip");

        ArgumentCaptor<Todo> captor = ArgumentCaptor.forClass(Todo.class);
        verify(repository, times(2)).save(captor.capture());
        assertThat(captor.getAllValues().get(0).getStatus()).isEqualTo(Todo.TodoStatus.SKIPPED);
        assertThat(captor.getAllValues().get(1).getDueAt()).isEqualTo(due.plusWeeks(1));
        assertThat(captor.getAllValues().get(1).getOccurrenceNumber()).isEqualTo(5);
    }
}
