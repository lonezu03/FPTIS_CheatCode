package com.fittrack.auth.service;

import com.fittrack.common.exception.TooManyRequestsException;
import org.springframework.stereotype.Service;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.Duration;
import java.time.Instant;
import java.util.HexFormat;
import java.util.concurrent.ConcurrentHashMap;

@Service
public class AuthRateLimitService {

    private final ConcurrentHashMap<String, Window> windows = new ConcurrentHashMap<>();

    public void check(
            String operation,
            String clientAddress,
            String identity,
            int limit,
            Duration duration
    ) {
        String key = operation + ':' + digest(clientAddress + '|' + identity);
        Instant now = Instant.now();
        Window window = windows.compute(key, (ignored, current) -> {
            if (current == null || !current.endsAt().isAfter(now)) {
                return new Window(1, now.plus(duration));
            }
            return new Window(current.count() + 1, current.endsAt());
        });
        if (windows.size() > 10_000) {
            windows.entrySet().removeIf(entry -> !entry.getValue().endsAt().isAfter(now));
        }
        if (window.count() > limit) {
            long retryAfter = Math.max(1, Duration.between(now, window.endsAt()).toSeconds());
            throw new TooManyRequestsException(
                    "Bạn thao tác quá nhanh. Vui lòng thử lại sau.",
                    retryAfter
            );
        }
    }

    private String digest(String value) {
        try {
            byte[] hash = MessageDigest.getInstance("SHA-256")
                    .digest(value.getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(hash, 0, 12);
        } catch (NoSuchAlgorithmException exception) {
            throw new IllegalStateException("SHA-256 is unavailable", exception);
        }
    }

    private record Window(int count, Instant endsAt) {
    }
}
