package com.fittrack.lunch.repository;

import com.fittrack.lunch.entity.LunchFundAccount;
import com.fittrack.user.entity.User;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Optional;

public interface LunchFundAccountRepository extends JpaRepository<LunchFundAccount, String> {

    Optional<LunchFundAccount> findByUser(User user);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select account from LunchFundAccount account where account.user = :user")
    Optional<LunchFundAccount> findByUserForUpdate(@Param("user") User user);
}
