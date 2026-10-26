package com.fittrack.mobilemenu;

import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;
import tools.jackson.databind.ObjectMapper;
import java.time.LocalDateTime;
import java.util.*;

@Service @RequiredArgsConstructor
public class MobileMenuService {
    public static final List<String> KEYS = List.of("dashboard", "lunch", "fitness",
            "workoutPlans", "exercises", "nutrition", "foods", "health", "planner",
            "quotes", "finance", "journal", "assistant");
    public record Entry(@NotBlank String key, @NotNull Boolean visible) {}
    public record Menu(@NotNull @Min(0) Long version,
                       @NotNull @Size(min = 13, max = 13) List<@Valid Entry> modules) {}
    private final MobileMenuRepository repository;
    private final ObjectMapper json;

    public static List<Entry> defaults() { return KEYS.stream().map(key -> new Entry(key, true)).toList(); }
    @Transactional(readOnly = true)
    public Menu get() {
        return response(repository.findById(1).orElseThrow(this::missingSettings));
    }
    @Transactional
    public Menu update(Menu input, String actor) {
        validate(input);
        var settings = repository.lock(1).orElseThrow(this::missingSettings);
        long current = settings.getVersion() == null ? 0 : settings.getVersion();
        if (input.version() != current) {
            throw new ResponseStatusException(HttpStatus.CONFLICT,
                    "Menu đã được cập nhật. Hãy tải lại, kiểm tra và lưu lại.");
        }
        settings.setModulesJson(json.writeValueAsString(input.modules()));
        settings.setUpdatedAt(LocalDateTime.now()); settings.setUpdatedBy(actor);
        return response(repository.saveAndFlush(settings));
    }
    private void validate(Menu menu) {
        if (menu == null || menu.version() == null || menu.version() < 0 || menu.modules() == null
                || menu.modules().size() != KEYS.size()) {
            throw new IllegalArgumentException("Cần toàn bộ danh sách module và phiên bản hợp lệ");
        }
        Set<String> seen = new HashSet<>();
        for (var entry : menu.modules()) {
            if (entry == null || entry.visible() == null || !KEYS.contains(entry.key()) || !seen.add(entry.key())) {
                throw new IllegalArgumentException("Module không hợp lệ, bị trùng hoặc thiếu trạng thái ẩn/hiện");
            }
        }
    }
    private ResponseStatusException missingSettings() {
        return new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE,
                "Chưa có cấu hình menu app. Kiểm tra migration V35 trước khi sử dụng.");
    }
    private Menu response(MobileMenuSettings row) {
        var entries = Arrays.asList(json.readValue(row.getModulesJson(), Entry[].class));
        var result = new Menu(row.getVersion(), entries); validate(result); return result;
    }
}
