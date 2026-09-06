package com.fittrack.quote.repository;

import com.fittrack.quote.entity.QuoteTag;
import com.fittrack.user.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface QuoteTagRepository extends JpaRepository<QuoteTag, String> {
    Optional<QuoteTag> findByUserAndName(User user, String name);
    List<QuoteTag> findByUserOrderByNameAsc(User user);
}
