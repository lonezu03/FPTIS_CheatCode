package com.fittrack.lunch.repository;

import com.fittrack.lunch.entity.LunchDishReview;
import com.fittrack.lunch.entity.LunchMenuItem;
import com.fittrack.lunch.entity.LunchOrder;
import com.fittrack.lunch.entity.LunchOrderStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Collection;
import java.util.List;
import java.util.Optional;

public interface LunchDishReviewRepository extends JpaRepository<LunchDishReview, String> {

    Optional<LunchDishReview> findByOrderAndMenuItem(LunchOrder order, LunchMenuItem menuItem);

    List<LunchDishReview> findByOrderOrderByCreatedAtAsc(LunchOrder order);

    List<LunchDishReview> findByMenuItemOrderByCreatedAtDesc(LunchMenuItem menuItem);

    List<LunchDishReview> findByMenuItem_IdOrderByCreatedAtDesc(String menuItemId);

    List<LunchDishReview> findByMenuItemAndOrder_StatusOrderByCreatedAtDesc(
            LunchMenuItem menuItem,
            LunchOrderStatus status
    );

    List<LunchDishReview> findByMenuItem_IdAndOrder_StatusOrderByCreatedAtDesc(
            String menuItemId,
            LunchOrderStatus status
    );

    @Query("""
            select review
            from LunchDishReview review
            where review.menuItem.id in :menuItemIds
              and review.order.status = :status
            """)
    List<LunchDishReview> findForMenuItems(
            @Param("menuItemIds") Collection<String> menuItemIds,
            @Param("status") LunchOrderStatus status
    );

    void deleteByOrder(LunchOrder order);
}
