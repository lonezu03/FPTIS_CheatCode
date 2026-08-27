package com.fittrack.notification.service;

import com.fittrack.common.exception.ResourceNotFoundException;
import com.fittrack.lunch.service.LunchNotificationService;
import com.fittrack.notification.dto.NotificationPlaybookDtos.*;
import com.fittrack.notification.entity.NotificationPlaybook;
import com.fittrack.notification.repository.NotificationPlaybookRepository;
import com.fittrack.nutrition.entity.MealLog;
import com.fittrack.nutrition.repository.MealLogRepository;
import com.fittrack.user.entity.User;
import com.fittrack.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Duration;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.concurrent.ThreadLocalRandom;

@Slf4j
@Service
@RequiredArgsConstructor
public class NotificationPlaybookService {

    private final NotificationPlaybookRepository playbookRepository;
    private final UserRepository userRepository;
    private final MealLogRepository mealLogRepository;
    private final LunchNotificationService notificationService;

    @Transactional(readOnly = true)
    public List<PlaybookResponse> getAll() {
        return playbookRepository.findAll().stream()
                .map(this::toResponse)
                .toList();
    }

    @Transactional
    public PlaybookResponse create(User admin, PlaybookRequest request) {
        NotificationPlaybook playbook = NotificationPlaybook.builder()
                .createdBy(admin)
                .name(request.name())
                .category(request.category())
                .mode(request.mode())
                .triggerTime(LocalTime.parse(request.triggerTime()))
                .daysOfWeek(request.daysOfWeek())
                .messages(request.messages())
                .conditionType(request.conditionType())
                .threshold(request.threshold())
                .recipientMode(request.recipientMode())
                .enabled(request.enabled())
                .build();

        if (request.recipientMode() == RecipientMode.SELECTED) {
            playbook.setRecipients(resolveSelectedRecipients(request.recipientUserIds()));
        }

        return toResponse(playbookRepository.save(playbook));
    }

    @Transactional
    public PlaybookResponse update(String id, PlaybookRequest request) {
        NotificationPlaybook playbook = playbookRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy kịch bản"));

        playbook.setName(request.name());
        playbook.setCategory(request.category());
        playbook.setMode(request.mode());
        playbook.setTriggerTime(LocalTime.parse(request.triggerTime()));
        playbook.setDaysOfWeek(request.daysOfWeek());
        playbook.setMessages(request.messages());
        playbook.setConditionType(request.conditionType());
        playbook.setThreshold(request.threshold());
        playbook.setRecipientMode(request.recipientMode());
        playbook.setEnabled(request.enabled());

        if (request.recipientMode() == RecipientMode.SELECTED) {
            playbook.setRecipients(resolveSelectedRecipients(request.recipientUserIds()));
        } else {
            playbook.getRecipients().clear();
        }

        return toResponse(playbookRepository.save(playbook));
    }

    @Transactional
    public void delete(String id) {
        if (!playbookRepository.existsById(id)) {
            throw new ResourceNotFoundException("Không tìm thấy kịch bản");
        }
        playbookRepository.deleteById(id);
    }

    @Scheduled(cron = "0 */5 * * * *")
    @Transactional
    public void processPlaybooks() {
        LocalDateTime now = LocalDateTime.now();
        LocalDate today = now.toLocalDate();
        String dayName = today.getDayOfWeek().name();

        List<NotificationPlaybook> duePlaybooks = playbookRepository.findAllByEnabledTrue();

        for (NotificationPlaybook playbook : duePlaybooks) {
            if (today.equals(playbook.getLastTriggeredDate())) continue;
            if (!playbook.getDaysOfWeek().contains(dayName)) continue;
            LocalTime triggerTime = playbook.getTriggerTime();
            if (triggerTime == null) continue;
            long minutesSinceTrigger = Duration.between(LocalDateTime.of(today, triggerTime), now).toMinutes();
            if (minutesSinceTrigger < 0 || minutesSinceTrigger > 6) continue;

            log.info("Triggering playbook: {}", playbook.getName());
            executePlaybook(playbook, today);
            playbook.setLastTriggeredDate(today);
            playbookRepository.save(playbook);
        }
    }

    private Set<User> resolveSelectedRecipients(List<String> requestedIds) {
        if (requestedIds == null || requestedIds.isEmpty()) {
            throw new IllegalArgumentException("Chế độ chọn user phải có ít nhất một người nhận");
        }
        List<String> distinctIds = requestedIds.stream().filter(Objects::nonNull).distinct().toList();
        List<User> recipients = userRepository.findAllById(distinctIds);
        if (recipients.size() != distinctIds.size()
                || recipients.stream().anyMatch(user -> !Boolean.TRUE.equals(user.getActive()))) {
            throw new IllegalArgumentException("Danh sách người nhận có user không tồn tại hoặc đã bị khóa");
        }
        return new LinkedHashSet<>(recipients);
    }

    private void executePlaybook(NotificationPlaybook playbook, LocalDate date) {
        List<User> candidates = playbook.getRecipientMode() == RecipientMode.ALL_ACTIVE
                ? userRepository.findByActiveTrue()
                : new ArrayList<>(playbook.getRecipients());

        String[] messages = Arrays.stream(playbook.getMessages().split("\\R"))
                .map(String::trim)
                .filter(message -> !message.isBlank())
                .toArray(String[]::new);
        if (messages.length == 0) return;

        for (User user : candidates) {
            if (!Boolean.TRUE.equals(user.getActive())) continue;
            if (shouldNotify(user, playbook, date)) {
                String message = selectMessage(messages, playbook.getMode());
                notificationService.notifyUser(
                        user,
                        "PLAYBOOK_" + playbook.getCategory().name(),
                        playbook.getName(),
                        message,
                        "PLAYBOOK",
                        playbook.getId()
                );
            }
        }
    }

    private boolean shouldNotify(User user, NotificationPlaybook playbook, LocalDate date) {
        if (playbook.getConditionType() == ConditionType.ANY) return true;

        List<MealLog> logs = mealLogRepository.findByUserAndLogDate(user, date);
        return switch (playbook.getConditionType()) {
            case NO_MEAL -> logs.isEmpty();
            case MEALS_LT -> {
                int threshold = playbook.getThreshold() != null ? playbook.getThreshold().intValue() : 3;
                yield logs.size() < threshold;
            }
            case PROTEIN_GT -> {
                double threshold = playbook.getThreshold() != null ? playbook.getThreshold().doubleValue() : 150.0;
                double totalProtein = logs.stream().mapToDouble(l -> l.getTotalProtein() != null ? l.getTotalProtein() : 0.0).sum();
                yield totalProtein > threshold;
            }
            default -> true;
        };
    }

    private String selectMessage(String[] messages, Mode mode) {
        if (mode == Mode.FIXED) return messages[0];
        return messages[ThreadLocalRandom.current().nextInt(messages.length)];
    }

    private PlaybookResponse toResponse(NotificationPlaybook playbook) {
        return new PlaybookResponse(
                playbook.getId(),
                playbook.getName(),
                playbook.getCategory(),
                playbook.getMode(),
                playbook.getTriggerTime().format(DateTimeFormatter.ofPattern("HH:mm")),
                playbook.getDaysOfWeek(),
                playbook.getMessages(),
                playbook.getConditionType(),
                playbook.getThreshold(),
                playbook.getRecipientMode(),
                playbook.getRecipients().stream().map(User::getId).toList(),
                playbook.isEnabled(),
                playbook.getLastTriggeredDate(),
                playbook.getCreatedAt()
        );
    }
}
