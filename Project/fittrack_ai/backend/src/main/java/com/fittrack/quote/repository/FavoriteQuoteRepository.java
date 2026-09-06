package com.fittrack.quote.repository;

import com.fittrack.quote.entity.FavoriteQuote;
import com.fittrack.quote.entity.QuoteStatus;
import com.fittrack.user.entity.User;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface FavoriteQuoteRepository extends JpaRepository<FavoriteQuote, String> {
    Optional<FavoriteQuote> findByIdAndUser(String id, User user);

    Optional<FavoriteQuote> findFirstByUserAndContentHashAndIdNotOrderByCreatedAtAsc(
            User user,
            String contentHash,
            String excludedId
    );

    Optional<FavoriteQuote> findFirstByUserAndContentHashOrderByCreatedAtAsc(
            User user,
            String contentHash
    );

    @Query(
            value = """
                    select q from FavoriteQuote q
                    where q.user = :user
                      and (:status is null or q.status = :status)
                      and (:tag = '' or exists (
                          select tag.id from q.tags tag
                          where lower(tag.name) = lower(:tag)
                      ))
                      and (:query = ''
                       or lower(q.content) like lower(concat('%', :query, '%'))
                       or lower(coalesce(q.author, '')) like lower(concat('%', :query, '%'))
                       or lower(coalesce(q.sourceTitle, '')) like lower(concat('%', :query, '%'))
                       or lower(coalesce(q.personalNote, '')) like lower(concat('%', :query, '%'))
                       or exists (
                          select searchTag.id from q.tags searchTag
                          where lower(searchTag.name) like lower(concat('%', :query, '%'))
                       ))
                    order by q.updatedAt desc
                    """,
            countQuery = """
                    select count(q) from FavoriteQuote q
                    where q.user = :user
                      and (:status is null or q.status = :status)
                      and (:tag = '' or exists (
                          select tag.id from q.tags tag
                          where lower(tag.name) = lower(:tag)
                      ))
                      and (:query = ''
                       or lower(q.content) like lower(concat('%', :query, '%'))
                       or lower(coalesce(q.author, '')) like lower(concat('%', :query, '%'))
                       or lower(coalesce(q.sourceTitle, '')) like lower(concat('%', :query, '%'))
                       or lower(coalesce(q.personalNote, '')) like lower(concat('%', :query, '%'))
                       or exists (
                          select searchTag.id from q.tags searchTag
                          where lower(searchTag.name) like lower(concat('%', :query, '%'))
                       ))
                    """
    )
    Page<FavoriteQuote> search(
            @Param("user") User user,
            @Param("query") String query,
            @Param("tag") String tag,
            @Param("status") QuoteStatus status,
            Pageable pageable
    );

    @Query("""
            select q from FavoriteQuote q
            where q.user = :user
              and q.status = com.fittrack.quote.entity.QuoteStatus.ACTIVE
              and q.includeInDaily = true
              and not exists (
                  select display.id from DailyQuoteDisplay display
                  where display.user = :user
                    and display.quote = q
                    and display.cycleNumber = :cycleNumber
              )
            """)
    List<FavoriteQuote> findDailyCandidates(
            @Param("user") User user,
            @Param("cycleNumber") int cycleNumber
    );

    long countByUserAndStatusAndIncludeInDailyTrue(User user, QuoteStatus status);
}
