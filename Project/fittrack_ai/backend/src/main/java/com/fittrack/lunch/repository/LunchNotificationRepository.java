package com.fittrack.lunch.repository;

import com.fittrack.lunch.entity.LunchNotification;
import com.fittrack.user.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

public interface LunchNotificationRepository extends JpaRepository<LunchNotification, String> {

    List<LunchNotification> findTop50ByRecipientOrderByCreatedAtDesc(User recipient);

    long countByRecipientAndReadAtIsNull(User recipient);

    Optional<LunchNotification> findByIdAndRecipient(String id, User recipient);

    boolean existsByDeduplicationKey(String deduplicationKey);

    Page<LunchNotification> findByRecipientOrderByCreatedAtDesc(
            User recipient,
            Pageable pageable
    );

    @Modifying
    @Query("""
            update LunchNotification notification
            set notification.readAt = :readAt
            where notification.recipient = :recipient
              and notification.readAt is null
            """)
    int markAllRead(
            @Param("recipient") User recipient,
            @Param("readAt") LocalDateTime readAt
    );
}
