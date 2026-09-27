package com.fittrack.journal.repository;
import com.fittrack.journal.entity.JournalUnlockSession;
import com.fittrack.user.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import java.time.LocalDateTime;
import java.util.Optional;
public interface JournalUnlockSessionRepository extends JpaRepository<JournalUnlockSession,String>{Optional<JournalUnlockSession> findByUserAndTokenHashAndExpiresAtAfter(User user,String hash,LocalDateTime now);void deleteByUser(User user);long deleteByExpiresAtBefore(LocalDateTime now);}
