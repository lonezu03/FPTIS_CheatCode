package com.fittrack.bodytracking.repository;

import com.fittrack.bodytracking.entity.BodyMeasurement;
import com.fittrack.user.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

public interface BodyMeasurementRepository extends JpaRepository<BodyMeasurement, String> {
    List<BodyMeasurement> findByUserOrderByRecordDateDesc(User user);

    List<BodyMeasurement> findByUserOrderByRecordDateAsc(User user);

    List<BodyMeasurement> findByUserAndRecordDateBetweenOrderByRecordDateAsc(
            User user,
            LocalDate fromDate,
            LocalDate toDate
    );

    Optional<BodyMeasurement> findByIdAndUser(String id, User user);
}

