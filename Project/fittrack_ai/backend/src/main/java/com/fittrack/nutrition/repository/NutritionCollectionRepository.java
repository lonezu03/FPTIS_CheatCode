package com.fittrack.nutrition.repository;

import com.fittrack.nutrition.entity.NutritionCollection;
import com.fittrack.user.entity.User;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface NutritionCollectionRepository
        extends JpaRepository<NutritionCollection, String> {
    @EntityGraph(attributePaths = {"items", "items.food"})
    List<NutritionCollection> findByUserAndActiveTrueOrderByUpdatedAtDesc(User user);

    @EntityGraph(attributePaths = {"items", "items.food"})
    Optional<NutritionCollection> findByIdAndUser(String id, User user);
}
