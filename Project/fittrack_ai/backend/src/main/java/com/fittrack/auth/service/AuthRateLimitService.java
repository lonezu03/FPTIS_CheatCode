package com.fittrack.auth.service;

import com.fittrack.common.exception.TooManyRequestsException;
import com.fittrack.common.ratelimit.RateLimitStore;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.Duration;
import java.util.HexFormat;

@Service
@RequiredArgsConstructor
public class AuthRateLimitService {

    private final RateLimitStore store;

    public void check(
            String operation,
            String clientAddress,
            String identity,
            int limit,
            Duration duration
    ) {
        String key = "auth:" + operation + ':' + digest(clientAddress + '|' + identity);
        RateLimitStore.Hit hit = store.hit(key, duration);
        if (hit.count() > limit) {
            throw new TooManyRequestsException(
                    "Bạn thao tác quá nhanh. Vui lòng thử lại sau.",
                    Math.max(1, hit.retryAfter().toSeconds())
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
}
