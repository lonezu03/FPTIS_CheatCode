package com.fittrack.health.service;

import com.fittrack.health.dto.HealthDtos.ReminderRequest;
import com.fittrack.health.dto.HealthDtos.ReminderResponse;
import com.fittrack.health.entity.HealthReminder;
import com.fittrack.health.repository.HealthReminderRepository;
import com.fittrack.lunch.service.LunchNotificationService;
import com.fittrack.user.entity.User;
import lombok.RequiredArgsConstructor;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.*;
import java.util.Arrays;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class HealthReminderService {

    private static final ZoneId BUSINESS_ZONE =
            ZoneId.of("Asia/Ho_Chi_Minh");

    private final HealthReminderRepository reminderRepository;
    private final LunchNotificationService notificationService;

    @Transactional(readOnly = true)
    public List<ReminderResponse> getMine(User user) {
        return reminderRepository.findByUserOrderByReminderTimeAsc(user)
                .stream()
                .map(this::toResponse)
                .toList();
    }

    @Transactional
    public ReminderResponse create(User user, ReminderRequest request) {
        HealthReminder reminder = new HealthReminder();
        reminder.setUser(user);
        apply(reminder, request);
        return toResponse(reminderRepository.save(reminder));
    }

    @Transactional
    public ReminderResponse update(
            User user,
            String id,
            ReminderRequest request
    ) {
        HealthReminder reminder = reminderRepository.findByIdAndUser(id, user)
                .orElseThrow(() -> new IllegalArgumentException(
                        "Không tìm thấy nhắc nhở"
                ));
        apply(reminder, request);
        return toResponse(reminderRepository.save(reminder));
    }

    @Transactional
    public void delete(User user, String id) {
        HealthReminder reminder = reminderRepository.findByIdAndUser(id, user)
                .orElseThrow(() -> new IllegalArgumentException(
                        "Không tìm thấy nhắc nhở"
                ));
        reminderRepository.delete(reminder);
    }

    @Scheduled(cron = "0 * * * * *", zone = "Asia/Ho_Chi_Minh")
    @Transactional
    public void dispatchDueReminders() {
        ZonedDateTime now = ZonedDateTime.now(BUSINESS_ZONE);
        LocalDate today = now.toLocalDate();
        LocalTime currentMinute = now.toLocalTime().withSecond(0).withNano(0);

        reminderRepository.findByEnabledTrue().forEach(reminder -> {
            Set<DayOfWeek> days = parseDays(reminder.getDaysOfWeek());
            if (!days.contains(now.getDayOfWeek())
                    || !reminder.getReminderTime().equals(currentMinute)
                    || today.equals(reminder.getLastTriggeredDate())) {
                return;
            }
            notificationService.notifyUser(
                    reminder.getUser(),
                    "HEALTH_REMINDER",
                    reminder.getTitle(),
                    reminder.getMessage() == null
                            || reminder.getMessage().isBlank()
                            ? "Đã đến giờ thực hiện kế hoạch sức khỏe của bạn."
                            : reminder.getMessage(),
                    "REMINDER",
                    reminder.getId()
            );
            reminder.setLastTriggeredDate(today);
        });
    }

    private void apply(
            HealthReminder reminder,
            ReminderRequest request
    ) {
        reminder.setType(request.type());
        reminder.setTitle(request.title().trim());
        reminder.setMessage(
                request.message() == null ? null : request.message().trim()
        );
        reminder.setReminderTime(
                request.reminderTime().withSecond(0).withNano(0)
        );
        reminder.setDaysOfWeek(
                request.daysOfWeek()
                        .stream()
                        .sorted()
                        .map(Enum::name)
                        .collect(Collectors.joining(","))
        );
        reminder.setEnabled(
                request.enabled() == null || request.enabled()
        );
    }

    private ReminderResponse toResponse(HealthReminder reminder) {
        return new ReminderResponse(
                reminder.getId(),
                reminder.getType(),
                reminder.getTitle(),
                reminder.getMessage(),
                reminder.getReminderTime(),
                parseDays(reminder.getDaysOfWeek()),
                Boolean.TRUE.equals(reminder.getEnabled()),
                reminder.getLastTriggeredDate(),
                reminder.getCreatedAt()
        );
    }

    private Set<DayOfWeek> parseDays(String value) {
        if (value == null || value.isBlank()) {
            return Set.of();
        }
        return Arrays.stream(value.split(","))
                .map(DayOfWeek::valueOf)
                .collect(Collectors.toSet());
    }
}
