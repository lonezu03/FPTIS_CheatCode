package com.fittrack.journal.repository;

import com.fittrack.journal.entity.*;
import com.fittrack.user.entity.User;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;

import java.time.LocalDate;
import java.util.*;

public interface JournalPromptDisplayRepository extends JpaRepository<JournalPromptDisplay, String> {
    Optional<JournalPromptDisplay> findFirstByUserAndDisplayDateOrderByCreatedAtDesc(User user, LocalDate displayDate);

    @Query("select coalesce(max(d.cycleNumber), 1) from JournalPromptDisplay d where d.user = :user")
    int findCurrentCycle(@Param("user") User user);

    @Query("select d.prompt.id from JournalPromptDisplay d where d.user = :user and d.cycleNumber = :cycle")
    Set<String> findPromptIdsInCycle(@Param("user") User user, @Param("cycle") int cycle);
}
