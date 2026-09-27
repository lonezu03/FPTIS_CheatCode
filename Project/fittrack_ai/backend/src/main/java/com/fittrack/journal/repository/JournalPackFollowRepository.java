package com.fittrack.journal.repository;
import com.fittrack.journal.entity.*;
import com.fittrack.user.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
public interface JournalPackFollowRepository extends JpaRepository<JournalPackFollow,JournalPackFollow.Key>{List<JournalPackFollow> findByUser(User user);void deleteByUserAndPack(User user,JournalPromptPack pack);boolean existsByUserAndPack(User user,JournalPromptPack pack);}
