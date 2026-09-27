package com.fittrack.journal.repository;

import com.fittrack.journal.entity.*;
import org.springframework.data.domain.*;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface JournalPromptRepository extends JpaRepository<JournalPrompt, String> {
    List<JournalPrompt> findByActiveTrueOrderByCreatedAtAsc();
    int countByPackAndActiveTrue(JournalPromptPack pack);

    @Query("""
            select p from JournalPrompt p
            where p.active = true
              and (:category is null or p.category = :category)
              and (:depth is null or p.depth = :depth)
              and (:q = '' or lower(p.content) like lower(concat('%', :q, '%')))
            order by p.category, p.createdAt
            """)
    Page<JournalPrompt> searchActive(@Param("q") String q,
                                     @Param("category") JournalCategory category,
                                     @Param("depth") JournalDepth depth,
                                     Pageable pageable);

    @Query("""
            select p from JournalPrompt p
            where (:active is null or p.active = :active)
              and (:q = '' or lower(p.content) like lower(concat('%', :q, '%')))
            order by p.updatedAt desc
            """)
    Page<JournalPrompt> searchAdmin(@Param("q") String q, @Param("active") Boolean active, Pageable pageable);
}
