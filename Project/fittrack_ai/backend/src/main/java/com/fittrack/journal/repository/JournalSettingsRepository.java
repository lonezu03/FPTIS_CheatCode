package com.fittrack.journal.repository;

import com.fittrack.journal.entity.JournalSettings;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface JournalSettingsRepository extends JpaRepository<JournalSettings, String> {
    List<JournalSettings> findByReminderEnabledTrue();
}
