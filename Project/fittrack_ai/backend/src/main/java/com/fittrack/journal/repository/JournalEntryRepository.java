package com.fittrack.journal.repository;

import com.fittrack.journal.entity.*;
import com.fittrack.user.entity.User;
import org.springframework.data.domain.*;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;

import java.util.Optional;

public interface JournalEntryRepository extends JpaRepository<JournalEntry, String> {
    Optional<JournalEntry> findByIdAndUserAndArchivedAtIsNull(String id, User user);
    Optional<JournalEntry> findByPromptDisplayAndArchivedAtIsNull(JournalPromptDisplay display);

    @Query("""
            select e from JournalEntry e left join e.prompt p
            where e.user = :user and e.archivedAt is null
              and (:origin is null or e.origin = :origin)
              and (:q = '' or lower(coalesce(e.title, '')) like lower(concat('%', :q, '%'))
                   or lower(e.body) like lower(concat('%', :q, '%'))
                   or lower(coalesce(p.content, '')) like lower(concat('%', :q, '%')))
            order by e.entryDate desc, e.createdAt desc
            """)
    Page<JournalEntry> search(@Param("user") User user,
                              @Param("q") String q,
                              @Param("origin") JournalOrigin origin,
                              Pageable pageable);
}
