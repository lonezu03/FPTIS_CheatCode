package com.fittrack.workout.repository;

import com.fittrack.workout.entity.Exercise;
import com.fittrack.user.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import java.util.List;

public interface ExerciseRepository extends JpaRepository<Exercise, String> {
    List<Exercise> findByActiveTrueAndNameContainingIgnoreCaseOrderByNameAsc(String keyword);

    List<Exercise> findByActiveTrueOrderByNameAsc();

    List<Exercise> findByNameContainingIgnoreCaseOrderByNameAsc(String keyword);

    List<Exercise> findAllByOrderByNameAsc();

    List<Exercise> findBySubmittedByOrderByCreatedAtDesc(User submittedBy);

    @Query("""
            select exercise from Exercise exercise
            where (:includeInactive = true or exercise.active = true)
              and (:keyword = '' or lower(exercise.name) like lower(concat('%', :keyword, '%')))
            order by exercise.name asc
            """)
    Page<Exercise> searchPage(
            @Param("keyword") String keyword,
            @Param("includeInactive") boolean includeInactive,
            Pageable pageable
    );
}
