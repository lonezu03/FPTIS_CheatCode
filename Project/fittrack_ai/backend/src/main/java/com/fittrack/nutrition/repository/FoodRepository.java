package com.fittrack.nutrition.repository;

import com.fittrack.nutrition.entity.Food;
import com.fittrack.user.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import java.util.List;

public interface FoodRepository extends JpaRepository<Food, String> {
    List<Food> findByActiveTrueAndNameContainingIgnoreCaseOrderByNameAsc(String keyword);

    List<Food> findByActiveTrueOrderByNameAsc();

    List<Food> findByNameContainingIgnoreCaseOrderByNameAsc(String keyword);

    List<Food> findAllByOrderByNameAsc();

    List<Food> findBySubmittedByOrderByCreatedAtDesc(User submittedBy);

    @Query("""
            select food from Food food
            where (:includeInactive = true or food.active = true)
              and (:keyword = '' or lower(food.name) like lower(concat('%', :keyword, '%')))
            order by food.name asc
            """)
    Page<Food> searchPage(
            @Param("keyword") String keyword,
            @Param("includeInactive") boolean includeInactive,
            Pageable pageable
    );
}

