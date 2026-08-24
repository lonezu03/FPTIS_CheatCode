package com.fittrack.lunch.service;

import com.fittrack.common.exception.ResourceNotFoundException;
import com.fittrack.lunch.dto.LunchDtos.NotificationListResponse;
import com.fittrack.lunch.entity.LunchNotification;
import com.fittrack.lunch.mapper.LunchMapper;
import com.fittrack.lunch.repository.LunchNotificationRepository;
import com.fittrack.user.entity.User;
import com.fittrack.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import org.springframework.data.domain.PageRequest;
import com.fittrack.common.dto.PageResponse;
import com.fittrack.lunch.dto.LunchDtos.NotificationResponse;
import com.fittrack.auth.service.ApplicationMailService;
import com.fittrack.lunch.entity.LunchMenu;

import java.time.format.DateTimeFormatter;
import java.text.NumberFormat;
import java.util.Locale;

@Service
@RequiredArgsConstructor
public class LunchNotificationService {

    private final LunchNotificationRepository notificationRepository;
    private final UserRepository userRepository;
    private final LunchMapper mapper;
    private final ApplicationMailService mailService;

    @Transactional(readOnly = true)
    public NotificationListResponse getMine(User user) {
        return new NotificationListResponse(
                notificationRepository.countByRecipientAndReadAtIsNull(user),
                notificationRepository.findTop50ByRecipientOrderByCreatedAtDesc(user)
                        .stream()
                        .map(mapper::toNotificationResponse)
                        .toList()
        );
    }

    @Transactional(readOnly = true)
    public PageResponse<NotificationResponse> getMinePage(User user, int page, int size) {
        return PageResponse.from(notificationRepository.findByRecipientOrderByCreatedAtDesc(
                user,
                PageRequest.of(Math.max(page, 0), Math.min(Math.max(size, 1), 100))
        ).map(mapper::toNotificationResponse));
    }

    @Transactional
    public void markRead(User user, String id) {
        LunchNotification notification = notificationRepository.findByIdAndRecipient(id, user)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy thông báo"));
        if (notification.getReadAt() == null) {
            notification.setReadAt(LocalDateTime.now());
        }
    }

    @Transactional
    public void markAllRead(User user) {
        notificationRepository.markAllRead(user, LocalDateTime.now());
    }

    @Transactional
    public void notifyAdmins(
            String type,
            String title,
            String message,
            String referenceType,
            String referenceId
    ) {
        userRepository.findByRoleIgnoreCase("ADMIN")
                .forEach(admin -> create(admin, type, title, message, referenceType, referenceId));
    }

    @Transactional
    public void notifyUser(
            User user,
            String type,
            String title,
            String message,
            String referenceType,
            String referenceId
    ) {
        create(user, type, title, message, referenceType, referenceId);
    }

    @Transactional
    public boolean notifyUserOnce(
            User user,
            String type,
            String title,
            String message,
            String referenceType,
            String referenceId,
            String deduplicationKey
    ) {
        if (notificationRepository.existsByDeduplicationKey(deduplicationKey)) {
            return false;
        }
        create(user, type, title, message, referenceType, referenceId, deduplicationKey);
        return true;
    }

    @Transactional
    public int broadcast(
            String title,
            String message,
            boolean sendToAll,
            List<String> recipientUserIds
    ) {
        List<User> recipients = sendToAll
                ? userRepository.findByActiveTrue()
                : userRepository.findByIdInAndActiveTrue(recipientUserIds);
        recipients.forEach(user -> create(
                user,
                "ADMIN_ANNOUNCEMENT",
                title,
                message,
                "ANNOUNCEMENT",
                null
        ));
        return recipients.size();
    }

    public DeliverySummary broadcastMenuAvailable(LunchMenu menu) {
        List<User> recipients = userRepository.findByActiveTrue();
        String title = "Thực đơn trưa "
                + menu.getMenuDate().format(DateTimeFormatter.ofPattern("dd/MM/yyyy"))
                + " đã mở";
        String message = "Menu " + menu.getVendorName()
                + " đã sẵn sàng. Giá "
                + NumberFormat.getIntegerInstance(Locale.forLanguageTag("vi-VN"))
                        .format(menu.getPrice())
                + "đ/phần, chốt lúc "
                + menu.getCutoffAt().format(DateTimeFormatter.ofPattern("HH:mm dd/MM/yyyy"))
                + ". Vào FitTrack để chọn món.";

        notificationRepository.saveAll(recipients.stream()
                .map(user -> LunchNotification.builder()
                        .recipient(user)
                        .type("LUNCH_MENU_AVAILABLE")
                        .title(title)
                        .message(message)
                        .referenceType("LUNCH_MENU")
                        .referenceId(menu.getId())
                        .build())
                .toList());

        String emailContent = message
                + "\n\nDanh sách món:\n"
                + menu.getRawMenuText();
        int sent = 0;
        for (User recipient : recipients) {
            if (mailService.sendLunchMenuEmail(
                    recipient.getEmail(),
                    recipient.getFullName(),
                    title,
                    emailContent
            )) {
                sent++;
            }
        }
        return new DeliverySummary(recipients.size(), sent, recipients.size() - sent);
    }

    private void create(
            User recipient,
            String type,
            String title,
            String message,
            String referenceType,
            String referenceId
    ) {
        create(recipient, type, title, message, referenceType, referenceId, null);
    }

    private void create(
            User recipient,
            String type,
            String title,
            String message,
            String referenceType,
            String referenceId,
            String deduplicationKey
    ) {
        notificationRepository.save(LunchNotification.builder()
                .recipient(recipient)
                .type(type)
                .title(title)
                .message(message)
                .referenceType(referenceType)
                .referenceId(referenceId)
                .deduplicationKey(deduplicationKey)
                .build());
        if (Boolean.TRUE.equals(recipient.getEmailNotificationsEnabled())) {
            mailService.sendNotificationEmail(
                    recipient.getEmail(), recipient.getFullName(), title, message
            );
        }
    }

    public record DeliverySummary(
            int recipientCount,
            int emailSentCount,
            int emailFailedCount
    ) {
    }
}
