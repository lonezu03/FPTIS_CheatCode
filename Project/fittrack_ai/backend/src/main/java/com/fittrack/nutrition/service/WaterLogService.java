package com.fittrack.nutrition.service;

import com.fittrack.nutrition.dto.WaterLogRequest;
import com.fittrack.nutrition.dto.WaterLogResponse;
import com.fittrack.nutrition.entity.WaterLog;
import com.fittrack.nutrition.repository.WaterLogRepository;
import com.fittrack.user.entity.User;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
public class WaterLogService {

    private final WaterLogRepository repository;

    @Transactional
    public WaterLogResponse create(User user, WaterLogRequest request) {
        WaterLog saved = repository.save(WaterLog.builder()
                .user(user)
                .amountMl(request.getAmountMl())
                .loggedAt(request.getLoggedAt())
                .build());
        return response(saved);
    }

    @Transactional(readOnly = true)
    public List<WaterLogResponse> getByDate(User user, LocalDate date) {
        return entities(user, date).stream().map(this::response).toList();
    }

    @Transactional(readOnly = true)
    public int totalByDate(User user, LocalDate date) {
        return entities(user, date).stream()
                .map(WaterLog::getAmountMl)
                .mapToInt(Integer::intValue)
                .sum();
    }

    @Transactional
    public void delete(User user, String id) {
        WaterLog log = repository.findByIdAndUser(id, user)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy lần ghi nước"));
        repository.delete(log);
    }

    private List<WaterLog> entities(User user, LocalDate date) {
        return repository.findByUserAndLoggedAtBetweenOrderByLoggedAtDesc(
                user,
                date.atStartOfDay(),
                date.plusDays(1).atStartOfDay()
        );
    }

    private WaterLogResponse response(WaterLog log) {
        return WaterLogResponse.builder()
                .id(log.getId())
                .amountMl(log.getAmountMl())
                .loggedAt(log.getLoggedAt())
                .build();
    }
}
