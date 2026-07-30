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

@Service
@RequiredArgsConstructor
public class LunchNotificationService {

    private final LunchNotificationRepository notificationRepository;
    private final UserRepository userRepository;
    private final LunchMapper mapper;

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

    private void create(
            User recipient,
            String type,
            String title,
            String message,
            String referenceType,
            String referenceId
    ) {
        notificationRepository.save(LunchNotification.builder()
                .recipient(recipient)
                .type(type)
                .title(title)
                .message(message)
                .referenceType(referenceType)
                .referenceId(referenceId)
                .build());
    }
}
