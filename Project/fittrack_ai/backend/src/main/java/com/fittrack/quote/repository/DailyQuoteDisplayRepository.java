package com.fittrack.quote.repository;

import com.fittrack.quote.entity.DailyQuoteDisplay;
import com.fittrack.quote.entity.FavoriteQuote;
import com.fittrack.user.entity.User;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

public interface DailyQuoteDisplayRepository extends JpaRepository<DailyQuoteDisplay, String> {
    Optional<DailyQuoteDisplay> findByUserAndDisplayDate(User user, LocalDate displayDate);

    @Query("select coalesce(max(display.cycleNumber), 0) from DailyQuoteDisplay display where display.user = :user")
    int findCurrentCycle(@Param("user") User user);

    Page<DailyQuoteDisplay> findByUserOrderByDisplayDateDesc(User user, Pageable pageable);

    @Query("""
            select display.displayDate from DailyQuoteDisplay display
            where display.user = :user and display.quote = :quote
            order by display.displayDate desc
            """)
    List<LocalDate> findDisplayDates(
            @Param("user") User user,
            @Param("quote") FavoriteQuote quote
    );

    void deleteByUserAndQuote(User user, FavoriteQuote quote);
}
