package com.fittrack.lunch.repository;

import com.fittrack.lunch.entity.*;
import com.fittrack.user.entity.User;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

public interface LunchOrderRepository extends JpaRepository<LunchOrder, String> {

    List<LunchOrder> findByMenuAndBeneficiaryAndStatusOrderByCreatedAtAsc(
            LunchMenu menu,
            User beneficiary,
            LunchOrderStatus status
    );

    boolean existsByMenu(LunchMenu menu);

    List<LunchOrder> findByMenuAndStatusOrderByCreatedAtAsc(
            LunchMenu menu,
            LunchOrderStatus status
    );

    List<LunchOrder> findByMenuAndOrderedByAndStatusOrderByCreatedAtAsc(
            LunchMenu menu,
            User orderedBy,
            LunchOrderStatus status
    );

    List<LunchOrder> findByOrderedByAndBatchRequestIdOrderByCreatedAtAsc(
            User orderedBy,
            String batchRequestId
    );

    List<LunchOrder> findDistinctByItems_MenuItemAndStatus(
            LunchMenuItem menuItem,
            LunchOrderStatus status
    );

    @Query("""
            select lunchOrder
            from LunchOrder lunchOrder
            where lunchOrder.beneficiary = :user
               or lunchOrder.orderedBy = :user
            order by lunchOrder.menu.menuDate desc, lunchOrder.createdAt desc
            """)
    List<LunchOrder> findHistoryForUser(@Param("user") User user);

    @Query("""
            select lunchOrder
            from LunchOrder lunchOrder
            where lunchOrder.beneficiary = :user
               or lunchOrder.orderedBy = :user
            order by lunchOrder.menu.menuDate desc, lunchOrder.createdAt desc
            """)
    Page<LunchOrder> findHistoryForUser(
            @Param("user") User user,
            Pageable pageable
    );

    boolean existsByBeneficiaryAndStatusAndPaymentStatusAndMenu_MenuDateBefore(
            User beneficiary,
            LunchOrderStatus status,
            LunchPaymentStatus paymentStatus,
            LocalDate menuDate
    );

    long countByMenuAndStatus(LunchMenu menu, LunchOrderStatus status);

    long countByMenuAndStatusAndPaymentStatus(
            LunchMenu menu,
            LunchOrderStatus status,
            LunchPaymentStatus paymentStatus
    );

    long countByBeneficiaryAndStatusAndPaymentStatus(
            User beneficiary,
            LunchOrderStatus status,
            LunchPaymentStatus paymentStatus
    );

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select lunchOrder from LunchOrder lunchOrder where lunchOrder.id = :id")
    Optional<LunchOrder> findByIdForUpdate(@Param("id") String id);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("""
            select lunchOrder
            from LunchOrder lunchOrder
            where lunchOrder.menu = :menu
              and lunchOrder.status = :status
            order by lunchOrder.createdAt asc
            """)
    List<LunchOrder> findByMenuAndStatusForUpdate(
            @Param("menu") LunchMenu menu,
            @Param("status") LunchOrderStatus status
    );
}
