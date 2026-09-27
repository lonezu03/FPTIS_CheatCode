package com.fittrack.journal.repository;

import com.fittrack.journal.entity.*;
import com.fittrack.user.entity.User;
import org.springframework.data.domain.*;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;

import java.util.Optional;
import java.util.List;
import java.time.LocalDate;

public interface JournalEntryRepository extends JpaRepository<JournalEntry, String> {
    Optional<JournalEntry> findByIdAndUserAndArchivedAtIsNull(String id, User user);
    Optional<JournalEntry> findByPromptDisplayAndArchivedAtIsNull(JournalPromptDisplay display);

    @Query("""
            select e from JournalEntry e left join e.prompt p
            where e.user = :user and e.archivedAt is null
              and (:origin is null or e.origin = :origin)
              and (:mood is null or e.mood = :mood)
              and (:fromDate is null or e.entryDate >= :fromDate)
              and (:toDate is null or e.entryDate <= :toDate)
              and (:tag = '' or exists (select jt.id from e.tags jt where lower(jt.name)=lower(:tag)))
              and (:q = '' or lower(coalesce(e.title, '')) like lower(concat('%', :q, '%'))
                   or lower(e.body) like lower(concat('%', :q, '%'))
                   or lower(coalesce(p.content, '')) like lower(concat('%', :q, '%'))
                   or exists (select st.id from e.tags st where lower(st.name) like lower(concat('%', :q, '%'))))
            order by e.entryDate desc, e.createdAt desc
            """)
    Page<JournalEntry> search(@Param("user") User user,
                              @Param("q") String q,
                              @Param("origin") JournalOrigin origin,
                              @Param("mood") JournalMood mood,
                              @Param("tag") String tag,
                              @Param("fromDate") LocalDate fromDate,
                              @Param("toDate") LocalDate toDate,
                              Pageable pageable);

    @Query("select e from JournalEntry e where e.user=:user and e.archivedAt is null and month(e.entryDate)=:month and day(e.entryDate)=:day and e.entryDate<:today order by e.entryDate desc")
    List<JournalEntry> onThisDay(@Param("user") User user,@Param("month") int month,@Param("day") int day,@Param("today") LocalDate today);

    @Query("select e from JournalEntry e where e.user=:user and e.archivedAt is null and e.entryDate between :from and :to order by e.entryDate asc")
    List<JournalEntry> findPeriod(@Param("user") User user,@Param("from") LocalDate from,@Param("to") LocalDate to);
}
