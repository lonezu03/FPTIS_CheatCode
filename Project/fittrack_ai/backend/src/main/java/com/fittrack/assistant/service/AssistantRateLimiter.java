package com.fittrack.assistant.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayDeque;
import java.util.Deque;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Component
public class AssistantRateLimiter {

    private static final Duration WINDOW = Duration.ofMinutes(1);

    private final Map<String, Deque<Instant>> requests = new ConcurrentHashMap<>();
    private final int requestsPerMinute;
    private final Clock clock;

    @Autowired
    public AssistantRateLimiter(
            @Value("${app.assistant.requests-per-minute:6}") int requestsPerMinute
    ) {
        this(requestsPerMinute, Clock.systemUTC());
    }

    AssistantRateLimiter(int requestsPerMinute, Clock clock) {
        this.requestsPerMinute = Math.max(1, requestsPerMinute);
        this.clock = clock;
    }

    public boolean tryAcquire(String userId) {
        Deque<Instant> userRequests = requests.computeIfAbsent(
                userId,
                ignored -> new ArrayDeque<>()
        );
        synchronized (userRequests) {
            Instant now = clock.instant();
            Instant cutoff = now.minus(WINDOW);
            while (!userRequests.isEmpty()
                    && !userRequests.peekFirst().isAfter(cutoff)) {
                userRequests.removeFirst();
            }
            if (userRequests.size() >= requestsPerMinute) {
                return false;
            }
            userRequests.addLast(now);
            return true;
        }
    }
}
