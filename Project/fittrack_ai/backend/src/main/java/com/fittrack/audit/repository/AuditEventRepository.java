package com.fittrack.audit.repository;

import com.fittrack.audit.entity.AuditEvent;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

public interface AuditEventRepository extends JpaRepository<AuditEvent, String> {
    Page<AuditEvent> findAllByOrderByCreatedAtDesc(Pageable pageable);
}
