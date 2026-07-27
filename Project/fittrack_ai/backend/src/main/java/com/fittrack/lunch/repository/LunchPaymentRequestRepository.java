package com.fittrack.lunch.repository;

import com.fittrack.lunch.entity.LunchPaymentRequest;
import com.fittrack.lunch.entity.LunchPaymentRequestStatus;
import com.fittrack.user.entity.User;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface LunchPaymentRequestRepository extends JpaRepository<LunchPaymentRequest, String> {

    List<LunchPaymentRequest> findByUserOrderByCreatedAtDesc(User user);

    List<LunchPaymentRequest> findAllByOrderByCreatedAtDesc();

    boolean existsByUserAndStatus(User user, LunchPaymentRequestStatus status);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select request from LunchPaymentRequest request where request.id = :id")
    Optional<LunchPaymentRequest> findByIdForUpdate(@Param("id") String id);
}
