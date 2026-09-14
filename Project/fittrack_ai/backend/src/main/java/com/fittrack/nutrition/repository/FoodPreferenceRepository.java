package com.fittrack.nutrition.repository;

import com.fittrack.nutrition.entity.FoodPreference;
import com.fittrack.user.entity.User;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface FoodPreferenceRepository extends JpaRepository<FoodPreference, String> {
    Optional<FoodPreference> findByUserAndFoodId(User user, String foodId);
    List<FoodPreference> findByUserAndFavoriteTrueOrderByUpdatedAtDesc(User user);
    List<FoodPreference> findByUserAndLastUsedAtIsNotNullOrderByLastUsedAtDesc(
            User user, Pageable pageable
    );
}
