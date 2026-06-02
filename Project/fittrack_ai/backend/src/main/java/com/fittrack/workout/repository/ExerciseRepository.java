package com.fittrack.workout.repository;

import com.fittrack.workout.entity.Exercise;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface ExerciseRepository extends JpaRepository<Exercise, String> {
    List<Exercise> findByActiveTrueAndNameContainingIgnoreCaseOrderByNameAsc(String keyword);

    List<Exercise> findByActiveTrueOrderByNameAsc();

    List<Exercise> findByNameContainingIgnoreCaseOrderByNameAsc(String keyword);

    List<Exercise> findAllByOrderByNameAsc();
}