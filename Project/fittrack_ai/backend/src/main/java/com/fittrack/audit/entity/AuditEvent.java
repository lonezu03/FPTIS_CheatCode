package com.fittrack.audit.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "audit_events", indexes = {
        @Index(name = "idx_audit_events_created", columnList = "created_at"),
        @Index(name = "idx_audit_events_actor", columnList = "actor_id,created_at"),
        @Index(name = "idx_audit_events_resource", columnList = "resource_type,resource_id")
})
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AuditEvent {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private String id;

    @Column(length = 255)
    private String actorId;

    @Column(length = 255)
    private String actorEmail;

    @Column(nullable = false, length = 80)
    private String action;

    @Column(nullable = false, length = 80)
    private String resourceType;

    @Column(length = 255)
    private String resourceId;

    @Column(columnDefinition = "text")
    private String details;

    @Column(length = 64)
    private String requestId;

    @Column(length = 80)
    private String clientAddress;

    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    void onCreate() {
        if (createdAt == null) createdAt = LocalDateTime.now();
    }
}
