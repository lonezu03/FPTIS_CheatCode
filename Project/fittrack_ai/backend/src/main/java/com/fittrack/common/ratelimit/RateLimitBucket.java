package com.fittrack.common.ratelimit;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import java.time.Instant;

// Mapped only so Hibernate validates the Flyway table and H2 test schemas create it; RateLimitStore uses SQL.
@Entity
@Table(name = "rate_limit_buckets")
public class RateLimitBucket {

    @Id
    @Column(name = "bucket_key", length = 200)
    private String bucketKey;

    @Column(name = "hit_count", nullable = false)
    private int hitCount;

    @Column(name = "window_ends_at", nullable = false)
    private Instant windowEndsAt;

    protected RateLimitBucket() {
    }
}
