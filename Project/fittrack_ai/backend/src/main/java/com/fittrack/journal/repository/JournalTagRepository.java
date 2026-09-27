package com.fittrack.journal.repository;
import com.fittrack.journal.entity.JournalTag;
import com.fittrack.user.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.*;
public interface JournalTagRepository extends JpaRepository<JournalTag,String>{Optional<JournalTag> findByUserAndName(User user,String name);List<JournalTag> findByUserOrderByNameAsc(User user);}
