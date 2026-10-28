package com.fittrack.sharing;

import com.fittrack.user.entity.User;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import java.time.LocalDateTime;

@Entity @Table(name = "template_shares") @Getter @Setter
public class TemplateShare {
    @Id @GeneratedValue(strategy = GenerationType.UUID) private String id;
    @ManyToOne(fetch = FetchType.LAZY, optional = false) @JoinColumn(name = "owner_id") private User owner;
    @ManyToOne(fetch = FetchType.LAZY, optional = false) @JoinColumn(name = "recipient_id") private User recipient;
    @Column(nullable = false, length = 30) private String kind;
    @Column(nullable = false) private String sourceId;
    @Column(nullable = false, length = 180) private String title;
    @Column(nullable = false, columnDefinition = "text") private String snapshot;
    @Column(nullable = false, length = 100) private String operationId;
    @Column(nullable = false, length = 64) private String requestDigest;
    @Column(nullable = false) private Boolean active;
    @Column(nullable = false) private LocalDateTime createdAt;
    @Column(nullable = false) private LocalDateTime expiresAt;
    private LocalDateTime copiedAt;
    @Column(columnDefinition = "text") private String copyResult;
    @Version private Long version;
}
