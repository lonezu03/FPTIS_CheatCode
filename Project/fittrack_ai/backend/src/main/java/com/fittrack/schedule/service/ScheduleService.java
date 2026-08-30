package com.fittrack.schedule.service;

import com.fittrack.common.exception.ResourceNotFoundException;
import com.fittrack.schedule.dto.ScheduleDtos.ScheduleRequest;
import com.fittrack.schedule.dto.ScheduleDtos.ScheduleResponse;
import com.fittrack.schedule.dto.ScheduleDtos.CalendarEntryResponse;
import com.fittrack.schedule.entity.ScheduleItem;
import com.fittrack.schedule.repository.ScheduleRepository;
import com.fittrack.user.entity.User;
import com.fittrack.todo.entity.Todo;
import com.fittrack.todo.repository.TodoRepository;
import com.fittrack.lunch.service.LunchNotificationService;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.DayOfWeek;
import java.time.Duration;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import java.util.Set;

@Service
@RequiredArgsConstructor
public class ScheduleService {
    private final ScheduleRepository repository;
    private final TodoRepository todoRepository;
    private final LunchNotificationService notificationService;

    @Value("${app.scheduler.internal-enabled:true}")
    private boolean internalSchedulerEnabled;

    @Transactional(readOnly = true)
    public List<ScheduleResponse> getMine(User user) {
        return repository.findByUserOrderByStartAtAsc(user).stream()
                .map(this::toResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<CalendarEntryResponse> getCalendar(User user, LocalDateTime from, LocalDateTime to) {
        if (from == null || to == null || !from.isBefore(to)) {
            throw new IllegalArgumentException("Khoảng thời gian lịch không hợp lệ");
        }
        if (Duration.between(from, to).toDays() > 370) {
            throw new IllegalArgumentException("Mỗi lần chỉ xem tối đa 370 ngày");
        }
        List<CalendarEntryResponse> result = new ArrayList<>();
        if (Boolean.TRUE.equals(user.getTodoEnabled()) || "ADMIN".equalsIgnoreCase(user.getRole())) {
            for (Todo todo : todoRepository.findByUserOrderByDueAtAscCreatedAtDesc(user)) {
                LocalDateTime start = todo.getStartAt() != null ? todo.getStartAt() : todo.getDueAt();
                if (start == null || start.isBefore(from) || !start.isBefore(to)) continue;
                LocalDateTime end = todo.getDueAt() != null && todo.getDueAt().isAfter(start)
                        ? todo.getDueAt() : todo.getEstimatedMinutes() == null ? null : start.plusMinutes(todo.getEstimatedMinutes());
                result.add(new CalendarEntryResponse(
                        "TODO:" + todo.getId(), "TODO", todo.getId(), todo.getTitle(), todo.getDescription(),
                        todo.getCategory().name(), start, end, todo.getStatus().name(),
                        todo.getRecurrenceRule() != Todo.RecurrenceRule.NONE
                ));
            }
        }
        for (ScheduleItem item : repository.findByUserAndEnabledTrueOrderByStartAtAsc(user)) {
            expandEvent(item, from, to, result);
        }
        return result.stream().sorted(Comparator.comparing(CalendarEntryResponse::startAt)
                .thenComparing(CalendarEntryResponse::title)).toList();
    }

    @Scheduled(cron = "20 * * * * *", zone = "Asia/Ho_Chi_Minh")
    @Transactional
    public void dispatchDueReminders() {
        if (!internalSchedulerEnabled) return;
        LocalDateTime now = LocalDateTime.now(java.time.ZoneId.of("Asia/Ho_Chi_Minh"));
        for (ScheduleItem item : repository.findAllByEnabledTrueAndReminderEnabledTrue()) {
            List<CalendarEntryResponse> occurrences = new ArrayList<>();
            expandEvent(item, now.minusDays(1), now.plusDays(8), occurrences);
            occurrences.stream()
                    .filter(entry -> !entry.startAt().minusMinutes(item.getReminderMinutes()).isAfter(now))
                    .filter(entry -> entry.startAt().isAfter(now.minusDays(1)))
                    .filter(entry -> item.getLastRemindedAt() == null
                            || item.getLastRemindedAt().isBefore(entry.startAt().minusMinutes(item.getReminderMinutes())))
                    .findFirst()
                    .ifPresent(entry -> {
                        notificationService.notifyUserOnce(
                                item.getUser(), "SCHEDULE_REMINDER", "Sắp đến lịch: " + item.getTitle(),
                                "Bắt đầu lúc " + entry.startAt().toLocalTime(), "SCHEDULE", item.getId(),
                                "schedule-reminder:" + item.getId() + ":" + entry.startAt()
                        );
                        item.setLastRemindedAt(now);
                    });
        }
    }

    @Transactional
    public ScheduleResponse create(User user, ScheduleRequest request) {
        ScheduleItem item = new ScheduleItem();
        item.setUser(user);
        apply(item, request);
        return toResponse(repository.save(item));
    }

    @Transactional
    public ScheduleResponse update(User user, String id, ScheduleRequest request) {
        ScheduleItem item = repository.findByIdAndUser(id, user)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy lịch"));
        apply(item, request);
        return toResponse(repository.save(item));
    }

    @Transactional
    public void delete(User user, String id) {
        ScheduleItem item = repository.findByIdAndUser(id, user)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy lịch"));
        repository.delete(item);
    }

    private void apply(ScheduleItem item, ScheduleRequest request) {
        item.setTitle(request.title().trim());
        item.setDescription(request.description() == null ? null : request.description().trim());
        item.setCategory(request.category() == null ? ScheduleItem.ScheduleCategory.PERSONAL : request.category());
        item.setStartAt(request.startAt());
        item.setEndAt(request.endAt());
        item.setRepeatRule(request.repeatRule() == null ? ScheduleItem.RepeatRule.NONE : request.repeatRule());
        item.setRepeatInterval(request.repeatInterval() == null ? 1 : request.repeatInterval());
        item.setRepeatEndAt(request.repeatEndAt());
        item.setDaysOfWeek(request.daysOfWeek() == null ? null : request.daysOfWeek().trim());
        item.setReminderMinutes(request.reminderMinutes() == null ? 10 : request.reminderMinutes());
        item.setReminderEnabled(request.reminderEnabled() == null || request.reminderEnabled());
        item.setEnabled(request.enabled() == null || request.enabled());
        if (item.getEndAt() != null && !item.getEndAt().isAfter(item.getStartAt())) {
            throw new IllegalArgumentException("Thời gian kết thúc phải sau thời gian bắt đầu");
        }
        if (item.getRepeatEndAt() != null && item.getRepeatEndAt().isBefore(item.getStartAt())) {
            throw new IllegalArgumentException("Ngày kết thúc lặp phải sau ngày bắt đầu");
        }
        if (item.getRepeatRule() == ScheduleItem.RepeatRule.NONE) {
            item.setRepeatInterval(1);
            item.setRepeatEndAt(null);
            item.setDaysOfWeek(null);
        }
    }

    private ScheduleResponse toResponse(ScheduleItem item) {
        return new ScheduleResponse(
                item.getId(), item.getTitle(), item.getDescription(), item.getCategory(), item.getStartAt(),
                item.getEndAt(), item.getRepeatRule(), item.getRepeatInterval(), item.getRepeatEndAt(),
                item.getDaysOfWeek(), item.getReminderMinutes(),
                Boolean.TRUE.equals(item.getReminderEnabled()), Boolean.TRUE.equals(item.getEnabled()),
                item.getLastRemindedAt(), item.getCreatedAt()
        );
    }

    private void expandEvent(ScheduleItem item, LocalDateTime from, LocalDateTime to,
                             List<CalendarEntryResponse> target) {
        if (item.getRepeatRule() == ScheduleItem.RepeatRule.NONE) {
            addEventOccurrence(item, item.getStartAt(), from, to, target);
            return;
        }
        LocalDateTime effectiveEnd = item.getRepeatEndAt() == null || item.getRepeatEndAt().isAfter(to)
                ? to : item.getRepeatEndAt().plusNanos(1);
        int interval = item.getRepeatInterval() == null ? 1 : item.getRepeatInterval();
        if (item.getRepeatRule() == ScheduleItem.RepeatRule.WEEKLY && !parseDays(item.getDaysOfWeek()).isEmpty()) {
            Set<DayOfWeek> days = parseDays(item.getDaysOfWeek());
            LocalDate date = item.getStartAt().toLocalDate();
            LocalDate lastDate = effectiveEnd.toLocalDate();
            while (!date.isAfter(lastDate)) {
                long weeks = ChronoUnit.WEEKS.between(item.getStartAt().toLocalDate(), date);
                if (weeks >= 0 && weeks % interval == 0 && days.contains(date.getDayOfWeek())) {
                    addEventOccurrence(item, LocalDateTime.of(date, item.getStartAt().toLocalTime()), from, to, target);
                }
                date = date.plusDays(1);
            }
            return;
        }
        LocalDateTime occurrence = item.getStartAt();
        int guard = 0;
        while (occurrence.isBefore(effectiveEnd) && guard++ < 20_000) {
            addEventOccurrence(item, occurrence, from, to, target);
            occurrence = switch (item.getRepeatRule()) {
                case DAILY -> occurrence.plusDays(interval);
                case WEEKLY -> occurrence.plusWeeks(interval);
                case MONTHLY -> occurrence.plusMonths(interval);
                case YEARLY -> occurrence.plusYears(interval);
                case NONE -> effectiveEnd;
            };
        }
    }

    private void addEventOccurrence(ScheduleItem item, LocalDateTime occurrence, LocalDateTime from,
                                    LocalDateTime to, List<CalendarEntryResponse> target) {
        if (occurrence.isBefore(from) || !occurrence.isBefore(to)) return;
        Duration duration = item.getEndAt() == null ? null : Duration.between(item.getStartAt(), item.getEndAt());
        target.add(new CalendarEntryResponse(
                "EVENT:" + item.getId() + ":" + occurrence, "EVENT", item.getId(), item.getTitle(),
                item.getDescription(), item.getCategory().name(), occurrence,
                duration == null ? null : occurrence.plus(duration), item.getEnabled() ? "ACTIVE" : "DISABLED",
                item.getRepeatRule() != ScheduleItem.RepeatRule.NONE
        ));
    }

    private Set<DayOfWeek> parseDays(String value) {
        if (value == null || value.isBlank()) return Set.of();
        Set<DayOfWeek> result = new HashSet<>();
        for (String raw : value.split(",")) {
            try { result.add(DayOfWeek.valueOf(raw.trim().toUpperCase(Locale.ROOT))); }
            catch (IllegalArgumentException ignored) { /* Validation is handled when the event is displayed. */ }
        }
        return result;
    }
}
