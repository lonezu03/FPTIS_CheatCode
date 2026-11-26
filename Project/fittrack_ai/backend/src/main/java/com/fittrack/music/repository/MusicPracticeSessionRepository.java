package com.fittrack.music.repository;

import com.fittrack.music.entity.MusicInstrument;
import com.fittrack.music.entity.MusicPracticeSession;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

public interface MusicPracticeSessionRepository extends JpaRepository<MusicPracticeSession, String> {

    Optional<MusicPracticeSession> findByIdAndUserId(String id, String userId);

    Page<MusicPracticeSession> findByUserIdAndPracticedOnBetween(
            String userId, LocalDate from, LocalDate to, Pageable pageable);

    Page<MusicPracticeSession> findByUserIdAndInstrumentAndPracticedOnBetween(
            String userId, MusicInstrument instrument, LocalDate from, LocalDate to, Pageable pageable);

    /** Rows: practicedOn, instrument, sum(minutes). */
    @Query("""
            select s.practicedOn, s.instrument, sum(s.minutes)
            from MusicPracticeSession s
            where s.user.id = :userId and s.practicedOn between :from and :to
            group by s.practicedOn, s.instrument
            """)
    List<Object[]> sumMinutesByDayAndInstrument(
            @Param("userId") String userId, @Param("from") LocalDate from, @Param("to") LocalDate to);

    /** Rows: instrument, sum(minutes), count(*). */
    @Query("""
            select s.instrument, sum(s.minutes), count(s)
            from MusicPracticeSession s
            where s.user.id = :userId
            group by s.instrument
            """)
    List<Object[]> totalsByInstrument(@Param("userId") String userId);

    @Query("""
            select distinct s.practicedOn
            from MusicPracticeSession s
            where s.user.id = :userId and s.practicedOn <= :today
            order by s.practicedOn desc
            """)
    List<LocalDate> practiceDatesUpTo(@Param("userId") String userId, @Param("today") LocalDate today);

    /** Rows: exerciseKey, instrument, best bpm, first day that bpm was reached. */
    @Query("""
            select s.exerciseKey, s.instrument, s.bpm, min(s.practicedOn)
            from MusicPracticeSession s
            where s.user.id = :userId and s.bpm is not null
              and s.bpm = (
                select max(b.bpm) from MusicPracticeSession b
                where b.user.id = :userId and b.exerciseKey = s.exerciseKey and b.instrument = s.instrument
              )
            group by s.exerciseKey, s.instrument, s.bpm
            """)
    List<Object[]> bestBpmByExercise(@Param("userId") String userId);
}
