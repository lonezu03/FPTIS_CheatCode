package com.fittrack.workout.repository;

import com.fittrack.user.entity.User;
import com.fittrack.workout.entity.ExercisePreference;
import com.fittrack.workout.entity.ExercisePreferenceLevel;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface ExercisePreferenceRepository
        extends JpaRepository<ExercisePreference, String> {

    List<ExercisePreference> findByUser(User user);

    Optional<ExercisePreference> findByUserAndExerciseId(
            User user,
            String exerciseId
    );

    List<ExercisePreference> findByUserAndPreference(
            User user,
            ExercisePreferenceLevel preference
    );
}
