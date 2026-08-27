package com.fittrack.lunch.repository;

import com.fittrack.lunch.entity.LunchMenu;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

public interface LunchMenuRepository extends JpaRepository<LunchMenu, String> {

    List<LunchMenu> findByMenuDateOrderByCreatedAtAsc(LocalDate menuDate);

    List<LunchMenu> findAllByOrderByMenuDateDesc();

    List<LunchMenu> findByMenuDateBetweenOrderByMenuDateDesc(LocalDate from, LocalDate to);

    List<LunchMenu> findByMenuDateGreaterThanEqualOrderByMenuDateDesc(LocalDate from);

    List<LunchMenu> findByMenuDateLessThanEqualOrderByMenuDateDesc(LocalDate to);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select menu from LunchMenu menu where menu.id = :id")
    Optional<LunchMenu> findByIdForUpdate(@Param("id") String id);
}
