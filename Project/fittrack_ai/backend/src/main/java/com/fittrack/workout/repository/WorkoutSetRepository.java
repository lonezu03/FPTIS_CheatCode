package com.fittrack.workout.repository;

import com.fittrack.user.entity.User;
import com.fittrack.workout.entity.WorkoutSet;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDate;
import java.util.List;

public interface WorkoutSetRepository extends JpaRepository<WorkoutSet, String> {

    @Query("""
            select workoutSet
            from WorkoutSet workoutSet
            join fetch workoutSet.session session
            join fetch workoutSet.exercise exercise
            where session.user = :user
              and exercise.id = :exerciseId
              and workoutSet.completed = true
            order by session.sessionDate desc, session.createdAt desc,
                     workoutSet.exerciseOrder asc, workoutSet.setNumber asc
            """)
    List<WorkoutSet> findCompletedByUserAndExercise(
            @Param("user") User user,
            @Param("exerciseId") String exerciseId
    );

    @Query("""
            select workoutSet
            from WorkoutSet workoutSet
            join fetch workoutSet.session session
            join fetch workoutSet.exercise exercise
            where session.user = :user
              and session.sessionDate between :fromDate and :toDate
              and workoutSet.completed = true
            """)
    List<WorkoutSet> findCompletedByUserAndDateBetween(
            @Param("user") User user,
            @Param("fromDate") LocalDate fromDate,
            @Param("toDate") LocalDate toDate
    );
}
