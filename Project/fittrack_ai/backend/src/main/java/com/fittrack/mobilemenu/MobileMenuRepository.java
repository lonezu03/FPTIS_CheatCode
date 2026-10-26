package com.fittrack.mobilemenu;

import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;
import java.util.Optional;

public interface MobileMenuRepository extends JpaRepository<MobileMenuSettings, Integer> {
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select s from MobileMenuSettings s where s.id = :id")
    Optional<MobileMenuSettings> lock(@Param("id") Integer id);
}
