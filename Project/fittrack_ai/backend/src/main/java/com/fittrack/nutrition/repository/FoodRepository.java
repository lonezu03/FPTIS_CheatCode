package com.fittrack.nutrition.repository;

import com.fittrack.nutrition.entity.Food;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface FoodRepository extends JpaRepository<Food, String> {
    List<Food> findByActiveTrueAndNameContainingIgnoreCaseOrderByNameAsc(String keyword);

    List<Food> findByActiveTrueOrderByNameAsc();

    List<Food> findByNameContainingIgnoreCaseOrderByNameAsc(String keyword);

    List<Food> findAllByOrderByNameAsc();
}

