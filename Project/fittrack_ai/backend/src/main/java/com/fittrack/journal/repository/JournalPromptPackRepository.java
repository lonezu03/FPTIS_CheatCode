package com.fittrack.journal.repository;
import com.fittrack.journal.entity.JournalPromptPack;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
public interface JournalPromptPackRepository extends JpaRepository<JournalPromptPack,String>{
    List<JournalPromptPack> findByActiveTrueOrderBySortOrderAscNameAsc();
    List<JournalPromptPack> findAllByOrderBySortOrderAscNameAsc();
}
