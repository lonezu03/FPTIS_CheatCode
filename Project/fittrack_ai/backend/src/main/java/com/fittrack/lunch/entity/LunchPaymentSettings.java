package com.fittrack.lunch.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "lunch_payment_settings")
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class LunchPaymentSettings {

    public static final String DEFAULT_ID = "default";

    @Id
    @Column(length = 30)
    private String id;

    @Column(columnDefinition = "TEXT")
    private String qrImageUrl;

    @Column(length = 120)
    private String bankName;

    @Column(length = 120)
    private String accountName;

    @Column(length = 80)
    private String accountNumber;

    @Column(length = 500)
    private String instructions;

    @Column(nullable = false)
    private LocalDateTime updatedAt;

    @Version
    private Long version;

    @PrePersist
    @PreUpdate
    public void touch() {
        if (id == null || id.isBlank()) {
            id = DEFAULT_ID;
        }
        updatedAt = LocalDateTime.now();
    }
}
