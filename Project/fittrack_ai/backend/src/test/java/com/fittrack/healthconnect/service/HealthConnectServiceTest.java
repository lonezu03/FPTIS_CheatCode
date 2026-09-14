package com.fittrack.healthconnect.service;

import com.fittrack.bodytracking.repository.BodyMeasurementRepository;
import com.fittrack.healthconnect.dto.HealthConnectDtos.SyncBatchRequest;
import com.fittrack.healthconnect.dto.HealthConnectDtos.SyncRecordRequest;
import com.fittrack.healthconnect.entity.HealthConnectRecord;
import com.fittrack.healthconnect.repository.HealthConnectRecordRepository;
import com.fittrack.user.entity.User;
import com.fittrack.user.repository.UserRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDateTime;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class HealthConnectServiceTest {
    @Mock HealthConnectRecordRepository repository;
    @Mock BodyMeasurementRepository bodyRepository;
    @Mock UserRepository userRepository;
    @InjectMocks HealthConnectService service;

    @Test
    void syncDeduplicatesRecordsAndMirrorsValidWeight() {
        User user = User.builder().id("user-1").weight(70.0).build();
        LocalDateTime now = LocalDateTime.now().minusMinutes(5);
        when(repository.existsByUserAndProviderAndExternalId(user, "HEALTH_CONNECT", "weight-1"))
                .thenReturn(false);
        when(repository.existsByUserAndProviderAndExternalId(user, "HEALTH_CONNECT", "steps-1"))
                .thenReturn(true);
        when(repository.save(any(HealthConnectRecord.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));
        SyncBatchRequest request = new SyncBatchRequest(List.of(
                new SyncRecordRequest("weight-1", "WEIGHT", "Health Connect", now, now, 71.2, "kg"),
                new SyncRecordRequest("steps-1", "STEPS", "Health Connect", now, now, 4000.0, "count"),
                new SyncRecordRequest("invalid-heart", "HEART_RATE", "Health Connect", now, now, 500.0, "bpm")
        ));

        var result = service.sync(user, request);

        assertThat(result.imported()).isEqualTo(1);
        assertThat(result.duplicates()).isEqualTo(1);
        assertThat(result.rejected()).isEqualTo(1);
        assertThat(user.getWeight()).isEqualTo(71.2);
        verify(bodyRepository).save(any());
        verify(userRepository).save(user);
    }
}
