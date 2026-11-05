package com.fittrack.common.ratelimit;

import com.fittrack.FittrackBackendApplication;
import com.fittrack.assistant.service.AssistantRateLimiter;
import com.fittrack.auth.service.AuthRateLimitService;
import com.fittrack.common.exception.TooManyRequestsException;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;

import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.ZoneId;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;
import java.util.TreeSet;
import java.util.UUID;
import java.util.concurrent.Callable;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

@SpringBootTest(classes = FittrackBackendApplication.class)
@ActiveProfiles("test")
class RateLimitStoreIntegrationTest {

    @Autowired JdbcTemplate jdbc;
    @Autowired PlatformTransactionManager transactionManager;
    @Autowired AuthRateLimitService authRateLimitService;
    @Autowired AssistantRateLimiter assistantRateLimiter;
    @Autowired RateLimitStore sharedStore;

    @Test
    void countsWithinWindowAndStartsOverAfterItEnds() {
        MutableClock clock = new MutableClock(Instant.parse("2026-11-05T01:00:00Z"));
        RateLimitStore store = new RateLimitStore(jdbc, transactionManager, clock);
        String key = uniqueKey();

        assertEquals(1, store.hit(key, Duration.ofMinutes(15)).count());
        clock.advance(Duration.ofMinutes(5));
        RateLimitStore.Hit second = store.hit(key, Duration.ofMinutes(15));
        assertEquals(2, second.count());
        assertEquals(Duration.ofMinutes(10), second.retryAfter());

        clock.advance(Duration.ofMinutes(10));
        RateLimitStore.Hit afterWindow = store.hit(key, Duration.ofMinutes(15));
        assertEquals(1, afterWindow.count());
        assertEquals(Duration.ofMinutes(15), afterWindow.retryAfter());
    }

    @Test
    void hitIsKeptWhenCallerTransactionRollsBack() {
        String key = uniqueKey();
        new TransactionTemplate(transactionManager).executeWithoutResult(status -> {
            sharedStore.hit(key, Duration.ofMinutes(1));
            status.setRollbackOnly();
        });

        assertEquals(2, sharedStore.hit(key, Duration.ofMinutes(1)).count());
    }

    @Test
    void concurrentFirstHitsAreEachCountedOnce() throws Exception {
        String key = uniqueKey();
        int threads = 8;
        CountDownLatch start = new CountDownLatch(1);
        ExecutorService executor = Executors.newFixedThreadPool(threads);
        try {
            List<Future<Integer>> results = new ArrayList<>();
            for (int i = 0; i < threads; i++) {
                Callable<Integer> task = () -> {
                    start.await();
                    return sharedStore.hit(key, Duration.ofMinutes(1)).count();
                };
                results.add(executor.submit(task));
            }
            start.countDown();
            Set<Integer> counts = new TreeSet<>();
            for (Future<Integer> result : results) {
                counts.add(result.get());
            }
            assertEquals(Set.of(1, 2, 3, 4, 5, 6, 7, 8), counts);
        } finally {
            executor.shutdownNow();
        }
    }

    @Test
    void authRejectsRequestsAboveLimitWithRetryAfter() {
        String email = uniqueKey() + "@example.com";
        authRateLimitService.check("login", "203.0.113.7", email, 2, Duration.ofMinutes(15));
        authRateLimitService.check("login", "203.0.113.7", email, 2, Duration.ofMinutes(15));

        TooManyRequestsException rejected = assertThrows(TooManyRequestsException.class, () ->
                authRateLimitService.check("login", "203.0.113.7", email, 2, Duration.ofMinutes(15)));
        assertTrue(rejected.getRetryAfterSeconds() > 0);

        authRateLimitService.check("login", "198.51.100.9", email, 2, Duration.ofMinutes(15));
    }

    @Test
    void assistantAllowsConfiguredRequestsPerMinute() {
        String userId = uniqueKey();
        for (int i = 0; i < 6; i++) {
            assertTrue(assistantRateLimiter.tryAcquire(userId));
        }
        assertFalse(assistantRateLimiter.tryAcquire(userId));
        assertTrue(assistantRateLimiter.tryAcquire("food-photo:" + userId));
    }

    private static String uniqueKey() {
        return "test:" + UUID.randomUUID();
    }

    private static final class MutableClock extends Clock {
        private Instant now;

        private MutableClock(Instant now) {
            this.now = now;
        }

        void advance(Duration duration) {
            now = now.plus(duration);
        }

        @Override
        public ZoneId getZone() {
            return ZoneOffset.UTC;
        }

        @Override
        public Clock withZone(ZoneId zone) {
            return this;
        }

        @Override
        public Instant instant() {
            return now;
        }
    }
}
