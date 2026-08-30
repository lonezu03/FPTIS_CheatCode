package com.fittrack.workout.repository;

import com.fittrack.user.entity.User;
import com.fittrack.workout.entity.WorkoutSession;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

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

    @Query("""
            select session
            from WorkoutSession session
            where session.user = :user
              and exists (
                  select workoutSet.id
                  from WorkoutSet workoutSet
                  where workoutSet.session = session
                    and workoutSet.exercise.id = :exerciseId
              )
            order by session.sessionDate desc, session.createdAt desc
            """)
    List<WorkoutSession> findLatestContainingExercise(
            @Param("user") User user,
            @Param("exerciseId") String exerciseId,
            Pageable pageable
    );
}
