package com.fittrack.common.ratelimit;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.TransactionDefinition;
import org.springframework.transaction.support.TransactionTemplate;

import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * Fixed-window hit counters shared by every application instance and kept across restarts.
 */
@Component
public class RateLimitStore {

    private static final int MAX_ATTEMPTS = 3;
    private static final int CLEANUP_EVERY_INSERTS = 200;

    private static final String INCREMENT = """
            UPDATE rate_limit_buckets
            SET hit_count = CASE WHEN window_ends_at <= ? THEN 1 ELSE hit_count + 1 END,
                window_ends_at = CASE WHEN window_ends_at <= ? THEN ? ELSE window_ends_at END
            WHERE bucket_key = ?
            """;
    private static final String READ =
            "SELECT hit_count, window_ends_at FROM rate_limit_buckets WHERE bucket_key = ?";
    private static final String INSERT =
            "INSERT INTO rate_limit_buckets (bucket_key, hit_count, window_ends_at) VALUES (?, 1, ?)";
    private static final String DELETE_EXPIRED =
            "DELETE FROM rate_limit_buckets WHERE window_ends_at <= ?";

    private final JdbcTemplate jdbc;
    private final TransactionTemplate independentTransaction;
    private final Clock clock;
    private final AtomicInteger inserts = new AtomicInteger();

    @Autowired
    public RateLimitStore(JdbcTemplate jdbc, PlatformTransactionManager transactionManager) {
        this(jdbc, transactionManager, Clock.systemUTC());
    }

    RateLimitStore(JdbcTemplate jdbc, PlatformTransactionManager transactionManager, Clock clock) {
        this.jdbc = jdbc;
        this.clock = clock;
        // Hits must commit even when the caller's request fails, e.g. a rejected login.
        this.independentTransaction = new TransactionTemplate(transactionManager);
        this.independentTransaction.setPropagationBehavior(TransactionDefinition.PROPAGATION_REQUIRES_NEW);
    }

    public Hit hit(String key, Duration window) {
        Instant now = clock.instant();
        OffsetDateTime nowValue = utc(now);
        OffsetDateTime freshEnd = utc(now.plus(window));
        for (int attempt = 0; attempt < MAX_ATTEMPTS; attempt++) {
            Hit existing = independentTransaction.execute(status -> increment(key, now, nowValue, freshEnd));
            if (existing != null) {
                return existing;
            }
            try {
                independentTransaction.executeWithoutResult(status -> jdbc.update(INSERT, key, freshEnd));
            } catch (DuplicateKeyException concurrentFirstHit) {
                continue;
            }
            removeExpiredOccasionally(nowValue);
            return new Hit(1, window);
        }
        throw new IllegalStateException("Rate limit bucket could not be updated");
    }

    private Hit increment(String key, Instant now, OffsetDateTime nowValue, OffsetDateTime freshEnd) {
        if (jdbc.update(INCREMENT, nowValue, nowValue, freshEnd, key) == 0) {
            return null;
        }
        return jdbc.queryForObject(READ, (row, index) -> new Hit(
                row.getInt("hit_count"),
                Duration.between(now, row.getObject("window_ends_at", OffsetDateTime.class).toInstant())
        ), key);
    }

    private void removeExpiredOccasionally(OffsetDateTime now) {
        if (inserts.incrementAndGet() % CLEANUP_EVERY_INSERTS == 0) {
            independentTransaction.executeWithoutResult(status -> jdbc.update(DELETE_EXPIRED, now));
        }
    }

    private static OffsetDateTime utc(Instant instant) {
        return instant.atOffset(ZoneOffset.UTC);
    }

    public record Hit(int count, Duration retryAfter) {
    }
}
