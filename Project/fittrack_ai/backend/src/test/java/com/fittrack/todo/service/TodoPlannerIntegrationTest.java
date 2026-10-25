package com.fittrack.todo.service;

import com.fittrack.FittrackBackendApplication;
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
import java.time.ZoneId;
import java.util.UUID;
import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest(classes = FittrackBackendApplication.class)
@ActiveProfiles("test")
@Transactional
class TodoPlannerIntegrationTest {
    @Autowired TodoService service;
    @Autowired TodoRepository todos;
    @Autowired UserRepository users;
    @Autowired jakarta.persistence.EntityManager entityManager;

    @Test
    void completedResponseTimestampMatchesReloadForUndoGuard() {
        User owner = user();
        var task = todos.saveAndFlush(Todo.builder().user(owner).title("undo")
                .status(Todo.TodoStatus.OPEN).priority(Todo.TodoPriority.MEDIUM)
                .category(Todo.TodoCategory.WORK).recurrenceRule(Todo.RecurrenceRule.NONE)
                .recurrenceInterval(1).reminderEnabled(false).build());
        var completed = service.complete(owner, task.getId());
        entityManager.clear();
        var reloaded = service.getOne(owner, task.getId());
        assertThat(completed.updatedAt()).isEqualTo(reloaded.updatedAt());
        assertThat(completed.status()).isEqualTo(Todo.TodoStatus.DONE);
    }

    @Test
    void plannerPagesCarryoverAndCountsWithinOwnerAndCategory() {
        User owner = user();
        User other = user();
        var yesterday = LocalDateTime.now(ZoneId.of("Asia/Ho_Chi_Minh")).minusDays(1);
        task(owner, "carry", Todo.TodoStatus.OPEN, yesterday);
        task(owner, "progress", Todo.TodoStatus.IN_PROGRESS, yesterday);
        task(owner, "skipped", Todo.TodoStatus.SKIPPED, yesterday);
        task(owner, "cancelled", Todo.TodoStatus.CANCELLED, yesterday);
        task(other, "private", Todo.TodoStatus.OPEN, yesterday);
        var page = service.getPage(owner, "TODAY", "WORK", null, 0, 1);
        assertThat(page.content()).hasSize(1);
        assertThat(page.totalElements()).isEqualTo(2);
        assertThat(page.totalPages()).isEqualTo(2);
        assertThat(page.counts().today()).isEqualTo(2);
        assertThat(page.counts().overdue()).isEqualTo(2);
        assertThat(service.getPage(owner, "OVERDUE", "WORK", null, 0, 10).content())
                .extracting(item -> item.title()).containsExactlyInAnyOrder("carry", "progress");
        assertThat(service.getPage(owner, "TODAY", "STUDY", null, 0, 10).totalElements()).isZero();
        assertThat(service.getPage(owner, "TODAY", "WORK", Todo.TodoStatus.IN_PROGRESS, 0, 10).totalElements()).isEqualTo(1);
    }

    @Test
    void upcomingExcludesFinishedAndCancelledInBothContracts() {
        User owner = user();
        var tomorrow = LocalDateTime.now(ZoneId.of("Asia/Ho_Chi_Minh")).plusDays(1);
        task(owner, "open", Todo.TodoStatus.OPEN, tomorrow);
        task(owner, "progress", Todo.TodoStatus.IN_PROGRESS, tomorrow);
        task(owner, "done", Todo.TodoStatus.DONE, tomorrow);
        task(owner, "cancelled", Todo.TodoStatus.CANCELLED, tomorrow);
        task(owner, "skipped", Todo.TodoStatus.SKIPPED, tomorrow);
        task(owner, "archived", Todo.TodoStatus.ARCHIVED, tomorrow);
        var page = service.getPage(owner, "UPCOMING", null, null, 0, 20);
        assertThat(page.content()).extracting(item -> item.title())
                .containsExactlyInAnyOrder("open", "progress");
        assertThat(page.counts().upcoming()).isEqualTo(2);
        assertThat(service.getMine(owner, "UPCOMING", null, null)).extracting(item -> item.title())
                .containsExactlyInAnyOrder("open", "progress");
    }

    private User user() {
        User user = new User();
        user.setEmail(UUID.randomUUID() + "@example.com");
        user.setPassword("test-only");
        return users.saveAndFlush(user);
    }

    private void task(User user, String title, Todo.TodoStatus status, LocalDateTime date) {
        todos.saveAndFlush(Todo.builder().user(user).title(title).status(status)
                .priority(Todo.TodoPriority.MEDIUM).category(Todo.TodoCategory.WORK)
                .startAt(date).dueAt(date.plusHours(1)).recurrenceRule(Todo.RecurrenceRule.NONE)
                .recurrenceInterval(1).reminderEnabled(false).build());
    }
}
