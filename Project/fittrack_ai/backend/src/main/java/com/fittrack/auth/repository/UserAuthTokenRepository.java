package com.fittrack.auth.repository;

import com.fittrack.auth.entity.UserAuthToken;
import com.fittrack.user.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface UserAuthTokenRepository
        extends JpaRepository<UserAuthToken, String> {

    Optional<UserAuthToken> findByTokenHashAndTypeAndUsedAtIsNull(
            String tokenHash,
            String type
    );

    void deleteByUserAndTypeAndUsedAtIsNull(User user, String type);
}
