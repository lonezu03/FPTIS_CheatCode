package com.fittrack.workout.repository;

import com.fittrack.user.entity.User;
import com.fittrack.workout.entity.WorkoutSession;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

public interface WorkoutSessionRepository extends JpaRepository<WorkoutSession, String> {
    List<WorkoutSession> findByUserOrderBySessionDateDesc(User user);

    Page<WorkoutSession> findByUserOrderBySessionDateDescCreatedAtDesc(
            User user,
            Pageable pageable
    );

    List<WorkoutSession> findByUserAndSessionDateOrderByCreatedAtDesc(User user, LocalDate sessionDate);

    List<WorkoutSession> findByUserAndSessionDateBetweenOrderBySessionDateAsc(
            User user,
            LocalDate fromDate,
            LocalDate toDate
    );

    Optional<WorkoutSession> findByIdAndUser(String id, User user);
}
