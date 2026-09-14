package com.fittrack.healthconnect.service;

import com.fittrack.bodytracking.entity.BodyMeasurement;
import com.fittrack.bodytracking.repository.BodyMeasurementRepository;
import com.fittrack.healthconnect.dto.HealthConnectDtos.*;
import com.fittrack.healthconnect.entity.HealthConnectRecord;
import com.fittrack.healthconnect.repository.HealthConnectRecordRepository;
import com.fittrack.user.entity.User;
import com.fittrack.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.Comparator;
import java.util.List;
import java.util.Set;

@Service
@RequiredArgsConstructor
public class HealthConnectService {
    private static final ZoneId BUSINESS_ZONE = ZoneId.of("Asia/Ho_Chi_Minh");
    private static final Set<String> TYPES = Set.of(
            "WEIGHT", "STEPS", "HEART_RATE", "EXERCISE_SESSION"
    );
    private final HealthConnectRecordRepository repository;
    private final BodyMeasurementRepository bodyRepository;
    private final UserRepository userRepository;

    @Transactional
    public SyncBatchResponse sync(User user, SyncBatchRequest request) {
        int imported = 0;
        int duplicates = 0;
        int rejected = 0;
        LocalDateTime futureLimit = LocalDateTime.now(BUSINESS_ZONE).plusMinutes(10);
        for (SyncRecordRequest item : request.records()) {
            String type = item.recordType().trim().toUpperCase();
            if (!TYPES.contains(type) || item.startAt().isAfter(futureLimit)
                    || !validValue(type, item.value())) {
                rejected++;
                continue;
            }
            if (repository.existsByUserAndProviderAndExternalId(
                    user, "HEALTH_CONNECT", item.externalId()
            )) {
                duplicates++;
                continue;
            }
            repository.save(HealthConnectRecord.builder()
                    .user(user)
                    .provider("HEALTH_CONNECT")
                    .externalId(item.externalId())
                    .recordType(type)
                    .sourceName(blankToNull(item.sourceName()))
                    .startAt(item.startAt())
                    .endAt(item.endAt())
                    .numericValue(item.value())
                    .unit(blankToNull(item.unit()))
                    .build());
            if ("WEIGHT".equals(type)) {
                bodyRepository.save(BodyMeasurement.builder()
                        .user(user)
                        .weight(item.value())
                        .recordDate(item.startAt().toLocalDate())
                        .build());
                user.setWeight(item.value());
            }
            imported++;
        }
        if (imported > 0) userRepository.save(user);
        return new SyncBatchResponse(imported, duplicates, rejected);
    }

    @Transactional(readOnly = true)
    public DailyHealthConnectResponse day(User user, LocalDate requestedDate) {
        LocalDate date = requestedDate == null ? LocalDate.now(BUSINESS_ZONE) : requestedDate;
        List<HealthConnectRecord> values = repository.findByUserAndStartAtBetweenOrderByStartAtDesc(
                user, date.atStartOfDay(), date.plusDays(1).atStartOfDay()
        );
        long steps = Math.round(values.stream()
                .filter(value -> "STEPS".equals(value.getRecordType()))
                .mapToDouble(value -> safe(value.getNumericValue())).sum());
        Double weight = values.stream().filter(value -> "WEIGHT".equals(value.getRecordType()))
                .filter(value -> value.getNumericValue() != null)
                .max(Comparator.comparing(HealthConnectRecord::getStartAt))
                .map(HealthConnectRecord::getNumericValue).orElse(null);
        double averageHeartRate = values.stream()
                .filter(value -> "HEART_RATE".equals(value.getRecordType()))
                .filter(value -> value.getNumericValue() != null)
                .mapToDouble(HealthConnectRecord::getNumericValue).average().orElse(0);
        int sessions = (int) values.stream()
                .filter(value -> "EXERCISE_SESSION".equals(value.getRecordType())).count();
        LocalDateTime lastSync = values.stream().map(HealthConnectRecord::getCreatedAt)
                .filter(java.util.Objects::nonNull).max(LocalDateTime::compareTo).orElse(null);
        return new DailyHealthConnectResponse(
                date, steps, weight, averageHeartRate == 0 ? null : round(averageHeartRate),
                sessions, lastSync
        );
    }

    private boolean validValue(String type, Double value) {
        if ("EXERCISE_SESSION".equals(type)) return true;
        if (value == null || value < 0) return false;
        return switch (type) {
            case "WEIGHT" -> value >= 20 && value <= 500;
            case "HEART_RATE" -> value >= 20 && value <= 300;
            case "STEPS" -> value <= 500_000;
            default -> false;
        };
    }

    private double safe(Double value) {
        return value == null ? 0 : value;
    }

    private double round(double value) {
        return Math.round(value * 10.0) / 10.0;
    }

    private String blankToNull(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }
}
