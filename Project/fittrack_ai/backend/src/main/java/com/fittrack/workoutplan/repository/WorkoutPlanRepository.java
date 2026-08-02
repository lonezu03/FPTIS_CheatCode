package com.fittrack.workoutplan.repository;

import com.fittrack.user.entity.User;
import com.fittrack.workoutplan.entity.WorkoutPlan;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import java.util.List;
import java.util.Optional;

public interface WorkoutPlanRepository extends JpaRepository<WorkoutPlan, String> {
    List<WorkoutPlan> findByUserOrderByCreatedAtDesc(User user);

    Page<WorkoutPlan> findByUserOrderByCreatedAtDesc(User user, Pageable pageable);

    Optional<WorkoutPlan> findByIdAndUser(String id, User user);
}

