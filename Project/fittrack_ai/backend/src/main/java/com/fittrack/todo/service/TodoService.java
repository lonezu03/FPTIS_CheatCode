package com.fittrack.todo.service;

import com.fittrack.common.exception.ResourceNotFoundException;
import com.fittrack.lunch.service.LunchNotificationService;
import com.fittrack.todo.dto.TodoDtos.SubtaskRequest;
import com.fittrack.todo.dto.TodoDtos.SubtaskResponse;
import com.fittrack.todo.dto.TodoDtos.TodoRequest;
import com.fittrack.todo.dto.TodoDtos.TodoResponse;
import com.fittrack.todo.entity.Todo;
import com.fittrack.todo.entity.TodoSubtask;
import com.fittrack.todo.repository.TodoRepository;
import com.fittrack.user.entity.User;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.PageRequest;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.Comparator;
import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import java.util.Objects;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class TodoService {
    private static final ZoneId BUSINESS_ZONE = ZoneId.of("Asia/Ho_Chi_Minh");

    private final TodoRepository repository;
    private final LunchNotificationService notificationService;

    @Value("${app.scheduler.internal-enabled:true}")
    private boolean internalSchedulerEnabled;

    @Transactional(readOnly = true)
    public List<TodoResponse> getMine(User user, String view, String category, Todo.TodoStatus status) {
        LocalDate today = LocalDate.now(BUSINESS_ZONE);
        return repository.findByUserOrderByDueAtAscCreatedAtDesc(user).stream()
                .filter(todo -> matchesView(todo, view, today))
                .filter(todo -> category == null || category.isBlank()
                        || todo.getCategory().name().equalsIgnoreCase(category))
                .filter(todo -> status == null || todo.getStatus() == status)
                .map(this::toResponse)
                .toList();
    }

    @Transactional
    public TodoResponse create(User user, TodoRequest request) {
        Todo todo = new Todo();
        todo.setUser(user);
        apply(todo, request, true);
        if (todo.getRecurrenceRule() != Todo.RecurrenceRule.NONE) {
            todo.setRecurringSeriesId(UUID.randomUUID().toString());
        }
        return toResponse(repository.save(todo));
    }

    @Transactional
    public TodoResponse update(User user, String id, TodoRequest request) {
        Todo todo = repository.findByIdAndUser(id, user)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy công việc"));
        Todo.TodoStatus previousStatus = todo.getStatus();
        LocalDateTime previousReminderAt = todo.getReminderAt();
        apply(todo, request, false);
        if (!Objects.equals(previousReminderAt, todo.getReminderAt())) todo.setReminderSentAt(null);
        if (todo.getRecurrenceRule() != Todo.RecurrenceRule.NONE && todo.getRecurringSeriesId() == null) {
            todo.setRecurringSeriesId(UUID.randomUUID().toString());
        }
        updateTransitionTimestamps(todo, previousStatus);
        Todo saved = repository.save(todo);
        if (isFinishedOccurrence(saved.getStatus())
                && !isFinishedOccurrence(previousStatus)
                && saved.getRecurrenceRule() != Todo.RecurrenceRule.NONE) {
            createNextOccurrence(saved);
        }
        return toResponse(saved);
    }

    @Transactional
    public TodoResponse complete(User user, String id) {
        return transition(user, id, Todo.TodoStatus.DONE);
    }

    @Transactional
    public TodoResponse skip(User user, String id) {
        Todo todo = repository.findByIdAndUser(id, user)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy công việc"));
        if (todo.getRecurrenceRule() == Todo.RecurrenceRule.NONE) {
            throw new IllegalArgumentException("Chỉ có thể bỏ qua một công việc đang lặp");
        }
        return transition(todo, Todo.TodoStatus.SKIPPED);
    }

    @Transactional
    public void delete(User user, String id) {
        Todo todo = repository.findByIdAndUser(id, user)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy công việc"));
        repository.delete(todo);
    }

    @Scheduled(cron = "0 * * * * *", zone = "Asia/Ho_Chi_Minh")
    @Transactional
    public void dispatchDueReminders() {
        if (internalSchedulerEnabled) dispatchDueRemindersNow();
    }

    @Transactional
    public int dispatchDueRemindersNow() {
        LocalDateTime now = LocalDateTime.now(BUSINESS_ZONE);
        int dispatched = 0;
        for (Todo todo : repository.findDueRemindersForUpdate(now, PageRequest.of(0, 100))) {
            if (todo.getStatus() == Todo.TodoStatus.DONE || todo.getStatus() == Todo.TodoStatus.ARCHIVED) {
                todo.setReminderSentAt(now);
                continue;
            }
            boolean created = notificationService.notifyUserOnce(
                    todo.getUser(), "TODO_REMINDER", "Đến giờ thực hiện công việc", reminderMessage(todo),
                    "TODO", todo.getId(), "todo-reminder:" + todo.getId() + ":" + todo.getReminderAt()
            );
            todo.setReminderSentAt(now);
            if (created) dispatched++;
        }
        return dispatched;
    }

    private void apply(Todo todo, TodoRequest request, boolean creating) {
        todo.setTitle(request.title().trim());
        todo.setDescription(trimToNull(request.description()));
        if (request.status() != null) todo.setStatus(request.status());
        if (request.priority() != null) todo.setPriority(request.priority());
        if (request.category() != null) todo.setCategory(request.category());
        if (request.recurrenceRule() != null) todo.setRecurrenceRule(request.recurrenceRule());
        if (request.recurrenceInterval() != null) todo.setRecurrenceInterval(request.recurrenceInterval());
        if (request.daysOfWeek() != null) todo.setDaysOfWeek(normalizeDays(request.daysOfWeek()));
        if (request.recurrenceBasis() != null) todo.setRecurrenceBasis(request.recurrenceBasis());
        todo.setRecurrenceEndAt(request.recurrenceEndAt());
        todo.setRecurrenceMaxOccurrences(request.recurrenceMaxOccurrences());
        todo.setStartAt(request.startAt());
        todo.setDueAt(request.dueAt());
        todo.setEstimatedMinutes(request.estimatedMinutes());
        todo.setReminderAt(request.reminderAt());
        todo.setReminderEnabled(Boolean.TRUE.equals(request.reminderEnabled()) && request.reminderAt() != null);
        if (todo.getReminderAt() == null) {
            todo.setReminderEnabled(false);
            todo.setReminderSentAt(null);
        }
        if (todo.getStartAt() != null && todo.getDueAt() != null && todo.getStartAt().isAfter(todo.getDueAt())) {
            throw new IllegalArgumentException("Thời gian bắt đầu phải trước hạn hoàn thành");
        }
        if (todo.getReminderAt() != null && todo.getDueAt() != null && todo.getReminderAt().isAfter(todo.getDueAt())) {
            throw new IllegalArgumentException("Thời điểm nhắc phải trước hạn hoàn thành");
        }
        if (todo.getStatus() == null) todo.setStatus(Todo.TodoStatus.OPEN);
        if (todo.getPriority() == null) todo.setPriority(Todo.TodoPriority.MEDIUM);
        if (todo.getCategory() == null) todo.setCategory(Todo.TodoCategory.PERSONAL);
        if (todo.getRecurrenceRule() == null) todo.setRecurrenceRule(Todo.RecurrenceRule.NONE);
        if (todo.getRecurrenceBasis() == null) todo.setRecurrenceBasis(Todo.RecurrenceBasis.SCHEDULED_DATE);
        if (todo.getRecurrenceInterval() == null || todo.getRecurrenceInterval() < 1) todo.setRecurrenceInterval(1);
        if (todo.getRecurrenceRule() == Todo.RecurrenceRule.NONE) {
            todo.setDaysOfWeek(null);
            todo.setRecurringSeriesId(null);
            todo.setRecurrenceBasis(Todo.RecurrenceBasis.SCHEDULED_DATE);
            todo.setRecurrenceEndAt(null);
            todo.setRecurrenceMaxOccurrences(null);
        }
        if (request.subtasks() != null || creating) replaceSubtasks(todo, request.subtasks());
    }

    private void replaceSubtasks(Todo todo, List<SubtaskRequest> requests) {
        if (todo.getSubtasks() == null) {
            todo.setSubtasks(new java.util.ArrayList<>());
        } else {
            try {
                todo.getSubtasks().clear();
            } catch (UnsupportedOperationException exception) {
                todo.setSubtasks(new java.util.ArrayList<>(todo.getSubtasks()));
                todo.getSubtasks().clear();
            }
        }
        if (requests == null) return;
        int fallbackOrder = 0;
        for (SubtaskRequest request : requests) {
            if (request == null || request.title() == null || request.title().isBlank()) continue;
            todo.getSubtasks().add(TodoSubtask.builder()
                    .todo(todo)
                    .title(request.title().trim())
                    .completed(Boolean.TRUE.equals(request.completed()))
                    .sortOrder(request.sortOrder() == null ? fallbackOrder : request.sortOrder())
                    .build());
            fallbackOrder++;
        }
        todo.getSubtasks().sort(Comparator.comparing(TodoSubtask::getSortOrder));
    }

    private void createNextOccurrence(Todo current) {
        LocalDateTime anchor = current.getDueAt() != null ? current.getDueAt()
                : current.getStartAt() != null ? current.getStartAt() : current.getReminderAt();
        if (anchor == null) return;
        int currentOccurrence = current.getOccurrenceNumber() == null ? 1 : current.getOccurrenceNumber();
        int nextOccurrenceNumber = currentOccurrence + 1;
        if (current.getRecurrenceMaxOccurrences() != null
                && nextOccurrenceNumber > current.getRecurrenceMaxOccurrences()) return;
        if (repository.existsByUserAndRecurringSeriesIdAndOccurrenceNumber(
                current.getUser(), current.getRecurringSeriesId(), nextOccurrenceNumber)) return;

        LocalDateTime recurrenceAnchor = anchor;
        if (current.getStatus() == Todo.TodoStatus.DONE
                && current.getRecurrenceBasis() == Todo.RecurrenceBasis.COMPLETION_DATE) {
            LocalDateTime completedAt = current.getCompletedAt() == null
                    ? LocalDateTime.now(BUSINESS_ZONE) : current.getCompletedAt();
            recurrenceAnchor = completedAt.withHour(anchor.getHour()).withMinute(anchor.getMinute())
                    .withSecond(anchor.getSecond()).withNano(anchor.getNano());
        }
        LocalDateTime nextAnchor = nextOccurrence(current, recurrenceAnchor);
        if (current.getRecurrenceEndAt() != null && nextAnchor.isAfter(current.getRecurrenceEndAt())) return;
        long reminderOffset = current.getReminderAt() == null ? 0L
                : java.time.Duration.between(current.getReminderAt(), anchor).toMinutes();
        Todo next = Todo.builder()
                .user(current.getUser()).title(current.getTitle()).description(current.getDescription())
                .status(Todo.TodoStatus.OPEN).priority(current.getPriority())
                .startAt(shift(current.getStartAt(), anchor, nextAnchor))
                .dueAt(shift(current.getDueAt(), anchor, nextAnchor))
                .estimatedMinutes(current.getEstimatedMinutes()).category(current.getCategory())
                .recurrenceRule(current.getRecurrenceRule()).recurrenceInterval(current.getRecurrenceInterval())
                .daysOfWeek(current.getDaysOfWeek()).recurringSeriesId(current.getRecurringSeriesId())
                .recurrenceBasis(current.getRecurrenceBasis()).recurrenceEndAt(current.getRecurrenceEndAt())
                .recurrenceMaxOccurrences(current.getRecurrenceMaxOccurrences()).occurrenceNumber(nextOccurrenceNumber)
                .reminderAt(current.getReminderAt() == null ? null : nextAnchor.minusMinutes(reminderOffset))
                .reminderEnabled(current.getReminderAt() != null).reminderSentAt(null).build();
        for (TodoSubtask subtask : current.getSubtasks()) {
            next.getSubtasks().add(TodoSubtask.builder().todo(next).title(subtask.getTitle())
                    .completed(false).sortOrder(subtask.getSortOrder()).build());
        }
        repository.save(next);
    }

    private LocalDateTime nextOccurrence(Todo todo, LocalDateTime anchor) {
        int interval = todo.getRecurrenceInterval() == null ? 1 : todo.getRecurrenceInterval();
        return switch (todo.getRecurrenceRule()) {
            case DAILY -> anchor.plusDays(interval);
            case MONTHLY -> anchor.plusMonths(interval);
            case YEARLY -> anchor.plusYears(interval);
            case CUSTOM -> anchor.plusDays(interval);
            case WEEKLY -> nextWeekly(todo, anchor, interval);
            case NONE -> anchor;
        };
    }

    private LocalDateTime nextWeekly(Todo todo, LocalDateTime anchor, int interval) {
        Set<DayOfWeek> days = parseDays(todo.getDaysOfWeek());
        if (days.isEmpty()) return anchor.plusWeeks(interval);
        for (int offset = 1; offset <= 7 * Math.max(interval, 1); offset++) {
            LocalDate candidate = anchor.toLocalDate().plusDays(offset);
            if (days.contains(candidate.getDayOfWeek())) return LocalDateTime.of(candidate, anchor.toLocalTime());
        }
        return anchor.plusWeeks(interval);
    }

    private LocalDateTime shift(LocalDateTime value, LocalDateTime oldAnchor, LocalDateTime newAnchor) {
        return value == null ? null : value.plus(java.time.Duration.between(oldAnchor, newAnchor));
    }

    private boolean matchesView(Todo todo, String view, LocalDate today) {
        if (view == null || view.isBlank() || "ALL".equalsIgnoreCase(view)) return true;
        if (todo.getStatus() == Todo.TodoStatus.DONE || todo.getStatus() == Todo.TodoStatus.ARCHIVED) {
            return "TODAY".equalsIgnoreCase(view) && hasDate(todo, today);
        }
        LocalDate taskDate = todo.getDueAt() != null ? todo.getDueAt().toLocalDate()
                : todo.getStartAt() != null ? todo.getStartAt().toLocalDate() : null;
        return switch (view.toUpperCase(Locale.ROOT)) {
            case "TODAY" -> hasDate(todo, today);
            case "OVERDUE" -> todo.getDueAt() != null && todo.getDueAt().toLocalDate().isBefore(today);
            case "UPCOMING" -> taskDate != null && taskDate.isAfter(today);
            default -> true;
        };
    }

    private boolean hasDate(Todo todo, LocalDate date) {
        return (todo.getDueAt() != null && todo.getDueAt().toLocalDate().equals(date))
                || (todo.getStartAt() != null && todo.getStartAt().toLocalDate().equals(date));
    }

    private TodoResponse toResponse(Todo todo) {
        List<String> days = parseDays(todo.getDaysOfWeek()).stream()
                .sorted(Comparator.comparingInt(DayOfWeek::getValue)).map(Enum::name).toList();
        List<SubtaskResponse> subtasks = todo.getSubtasks().stream()
                .sorted(Comparator.comparing(TodoSubtask::getSortOrder))
                .map(item -> new SubtaskResponse(item.getId(), item.getTitle(),
                        Boolean.TRUE.equals(item.getCompleted()), item.getSortOrder())).toList();
        return new TodoResponse(todo.getId(), todo.getTitle(), todo.getDescription(), todo.getStatus(), todo.getPriority(),
                todo.getStartAt(), todo.getDueAt(), todo.getEstimatedMinutes(), todo.getCategory(),
                todo.getRecurrenceRule(), todo.getRecurrenceInterval(), days, todo.getRecurrenceBasis(),
                todo.getRecurrenceEndAt(), todo.getRecurrenceMaxOccurrences(), todo.getOccurrenceNumber(),
                todo.getCompletedAt(), todo.getSkippedAt(), todo.getReminderAt(),
                Boolean.TRUE.equals(todo.getReminderEnabled()), todo.getRecurringSeriesId(), subtasks,
                todo.getCreatedAt(), todo.getUpdatedAt());
    }

    private String reminderMessage(Todo todo) {
        StringBuilder message = new StringBuilder("Đừng quên: ").append(todo.getTitle());
        if (todo.getDueAt() != null) message.append(" — hạn ").append(todo.getDueAt().toLocalTime());
        if (todo.getEstimatedMinutes() != null) message.append(" (dự kiến ").append(todo.getEstimatedMinutes()).append(" phút)");
        return message.toString();
    }

    private String normalizeDays(String value) {
        if (value == null || value.isBlank()) return null;
        return parseDays(value).stream().sorted(Comparator.comparingInt(DayOfWeek::getValue))
                .map(Enum::name).collect(Collectors.joining(","));
    }

    private Set<DayOfWeek> parseDays(String value) {
        if (value == null || value.isBlank()) return Set.of();
        Set<DayOfWeek> days = new HashSet<>();
        for (String raw : value.split(",")) {
            if (raw.isBlank()) continue;
            try { days.add(DayOfWeek.valueOf(raw.trim().toUpperCase(Locale.ROOT))); }
            catch (IllegalArgumentException exception) { throw new IllegalArgumentException("Ngày lặp không hợp lệ: " + raw.trim()); }
        }
        return days;
    }

    private String trimToNull(String value) { return value == null || value.isBlank() ? null : value.trim(); }

    private TodoResponse transition(User user, String id, Todo.TodoStatus status) {
        Todo todo = repository.findByIdAndUser(id, user)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy công việc"));
        return transition(todo, status);
    }

    private TodoResponse transition(Todo todo, Todo.TodoStatus status) {
        Todo.TodoStatus previousStatus = todo.getStatus();
        if (previousStatus == status) return toResponse(todo);
        todo.setStatus(status);
        updateTransitionTimestamps(todo, previousStatus);
        Todo saved = repository.save(todo);
        if (isFinishedOccurrence(status) && !isFinishedOccurrence(previousStatus)
                && saved.getRecurrenceRule() != Todo.RecurrenceRule.NONE) {
            createNextOccurrence(saved);
        }
        return toResponse(saved);
    }

    private void updateTransitionTimestamps(Todo todo, Todo.TodoStatus previousStatus) {
        if (todo.getStatus() == Todo.TodoStatus.DONE && previousStatus != Todo.TodoStatus.DONE) {
            todo.setCompletedAt(LocalDateTime.now(BUSINESS_ZONE));
            todo.setSkippedAt(null);
        } else if (todo.getStatus() == Todo.TodoStatus.SKIPPED && previousStatus != Todo.TodoStatus.SKIPPED) {
            todo.setSkippedAt(LocalDateTime.now(BUSINESS_ZONE));
            todo.setCompletedAt(null);
        } else if (!isFinishedOccurrence(todo.getStatus())) {
            todo.setCompletedAt(null);
            todo.setSkippedAt(null);
        }
    }

    private boolean isFinishedOccurrence(Todo.TodoStatus status) {
        return status == Todo.TodoStatus.DONE || status == Todo.TodoStatus.SKIPPED;
    }
}
