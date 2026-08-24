package com.fittrack.auth.repository;

import com.fittrack.auth.entity.UserAuthToken;
import com.fittrack.user.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import jakarta.persistence.LockModeType;
import java.time.LocalDateTime;

import java.util.Optional;

public interface UserAuthTokenRepository
        extends JpaRepository<UserAuthToken, String> {

    Optional<UserAuthToken> findByTokenHashAndTypeAndUsedAtIsNull(
            String tokenHash,
            String type
    );

    void deleteByUserAndTypeAndUsedAtIsNull(User user, String type);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    Optional<UserAuthToken> findFirstByUserAndTypeAndUsedAtIsNullOrderByCreatedAtDesc(
            User user,
            String type
    );

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("""
            select token from UserAuthToken token
            join fetch token.user
            where token.tokenHash = :tokenHash
              and token.type = :type
              and token.usedAt is null
            """)
    Optional<UserAuthToken> findValidForUpdate(
            @Param("tokenHash") String tokenHash,
            @Param("type") String type
    );

    long deleteByExpiresAtBefore(LocalDateTime cutoff);
}
