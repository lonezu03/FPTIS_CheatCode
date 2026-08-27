package com.fittrack.user.repository;

import com.fittrack.user.entity.User;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Optional;
import java.util.List;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

public interface UserRepository extends JpaRepository<User, String> {
    Optional<User> findByEmail(String email);

    boolean existsByEmail(String email);

    List<User> findByRoleIgnoreCase(String role);

    List<User> findByActiveTrue();

    List<User> findByIdInAndActiveTrue(List<String> ids);

    long countByRoleIgnoreCaseAndActiveTrue(String role);

    @Query("""
            select user
            from User user
            where user.deletedAt is null
              and (:keyword = ''
               or lower(user.email) like lower(concat('%', :keyword, '%'))
               or lower(coalesce(user.fullName, '')) like lower(concat('%', :keyword, '%')))
            order by user.createdAt desc
            """)
    List<User> searchForAdmin(@Param("keyword") String keyword);

    @Query("""
            select user
            from User user
            where user.deletedAt is null
              and (:keyword = ''
               or lower(user.email) like lower(concat('%', :keyword, '%'))
               or lower(coalesce(user.fullName, '')) like lower(concat('%', :keyword, '%')))
            order by user.createdAt desc
            """)
    Page<User> searchForAdminPage(
            @Param("keyword") String keyword,
            Pageable pageable
    );

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select user from User user where user.id = :id")
    Optional<User> findByIdForUpdate(@Param("id") String id);
}
