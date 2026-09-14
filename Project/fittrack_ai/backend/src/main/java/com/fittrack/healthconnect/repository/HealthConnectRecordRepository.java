package com.fittrack.healthconnect.repository;

import com.fittrack.healthconnect.entity.HealthConnectRecord;
import com.fittrack.user.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDateTime;
import java.util.List;

public interface HealthConnectRecordRepository extends JpaRepository<HealthConnectRecord, String> {
    boolean existsByUserAndProviderAndExternalId(User user, String provider, String externalId);
    List<HealthConnectRecord> findByUserAndStartAtBetweenOrderByStartAtDesc(
            User user, LocalDateTime from, LocalDateTime to
    );
}
