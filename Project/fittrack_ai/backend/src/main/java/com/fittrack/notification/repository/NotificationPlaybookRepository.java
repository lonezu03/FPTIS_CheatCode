package com.fittrack.notification.repository;

import com.fittrack.notification.entity.NotificationPlaybook;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface NotificationPlaybookRepository extends JpaRepository<NotificationPlaybook, String> {
    List<NotificationPlaybook> findAllByEnabledTrue();
}
