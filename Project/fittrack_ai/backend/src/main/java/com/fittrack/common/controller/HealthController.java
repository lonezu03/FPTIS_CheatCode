package com.fittrack.common.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.jdbc.core.JdbcTemplate;
import lombok.RequiredArgsConstructor;

import java.time.LocalDateTime;
import java.util.Map;

@RestController
@RequestMapping("/api/health")
@RequiredArgsConstructor
public class HealthController {

    private final JdbcTemplate jdbcTemplate;

    @GetMapping
    public Map<String, Object> health() {
        Integer databaseCheck = jdbcTemplate.queryForObject("select 1", Integer.class);
        return Map.of(
                "status", "UP",
                "database", databaseCheck != null && databaseCheck == 1 ? "UP" : "DOWN",
                "timestamp", LocalDateTime.now()
        );
    }
}
