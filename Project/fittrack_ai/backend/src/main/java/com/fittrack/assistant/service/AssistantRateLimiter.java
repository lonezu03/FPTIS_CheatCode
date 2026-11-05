package com.fittrack.assistant.service;

import com.fittrack.common.ratelimit.RateLimitStore;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.time.Duration;

@Component
public class AssistantRateLimiter {

    private static final Duration WINDOW = Duration.ofMinutes(1);

    private final RateLimitStore store;
    private final int requestsPerMinute;

    public AssistantRateLimiter(
            RateLimitStore store,
            @Value("${app.assistant.requests-per-minute:6}") int requestsPerMinute
    ) {
        this.store = store;
        this.requestsPerMinute = Math.max(1, requestsPerMinute);
    }

    public boolean tryAcquire(String userId) {
        return store.hit("assistant:" + userId, WINDOW).count() <= requestsPerMinute;
    }
}
