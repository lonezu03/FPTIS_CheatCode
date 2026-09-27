package com.fittrack.journal.service;

import com.fittrack.FittrackBackendApplication;
import com.fittrack.common.exception.ResourceNotFoundException;
import com.fittrack.journal.dto.JournalDtos.*;
import com.fittrack.journal.entity.*;
import com.fittrack.journal.repository.*;
import com.fittrack.user.entity.User;
import com.fittrack.user.repository.UserRepository;
import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

import java.time.LocalTime;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest(classes = FittrackBackendApplication.class)
@ActiveProfiles("test")
class JournalServiceIntegrationTest {
    @Autowired JournalService service;
    @Autowired UserRepository users;
    @Autowired JournalPromptRepository prompts;

    @BeforeEach
    void seedPrompts() {
        if (prompts.count() == 0) {
            prompts.save(prompt("Một điều nhỏ khiến bạn vui hôm nay là gì?"));
            prompts.save(prompt("Bạn muốn ghi nhớ điều gì của ngày hôm nay?"));
            prompts.save(prompt("Ngày mai bạn muốn làm khác đi điều gì?"));
        }
    }

    @Test
    void dailyPromptIsStableAndSkipDoesNotRepeatImmediately() {
        User user = user("journal-cycle");
        TodayResponse first = service.today(user);
        assertEquals(first.prompt().id(), service.today(user).prompt().id());

        TodayResponse next = service.skipToday(user);
        assertNotEquals(first.prompt().id(), next.prompt().id());
        assertEquals(next.prompt().id(), service.today(user).prompt().id());
    }

    @Test
    void entriesRemainOwnerScopedAndCanBeUpdatedAndArchived() {
        User owner = user("journal-owner");
        User other = user("journal-other");
        var created = service.create(owner, new EntryRequest(
                JournalOrigin.FREEFORM, null, null, "Ngày bình yên", "Một nội dung riêng tư", JournalMood.GOOD));

        assertEquals(1, service.list(owner, "riêng tư", null, 0, 20).totalElements());
        assertEquals(0, service.list(other, "", null, 0, 20).totalElements());
        assertThrows(ResourceNotFoundException.class, () -> service.get(other, created.id()));

        var updated = service.update(owner, created.id(), new EntryRequest(
                JournalOrigin.FREEFORM, null, created.entryDate(), "Đã sửa", "Nội dung mới", JournalMood.VERY_GOOD));
        assertEquals("Đã sửa", updated.title());
        service.delete(owner, created.id());
        assertEquals(0, service.list(owner, "", null, 0, 20).totalElements());
    }

    @Test
    void reminderSettingsUseExplicitOwnerPreference() {
        User user = user("journal-settings");
        assertFalse(service.getSettings(user).reminderEnabled());
        var saved = service.updateSettings(user, new ReminderSettingsRequest(true, LocalTime.of(7, 15)));
        assertTrue(saved.reminderEnabled());
        assertEquals(LocalTime.of(7, 15), saved.reminderTime());
    }

    private JournalPrompt prompt(String content) {
        return JournalPrompt.builder().content(content).category(JournalCategory.REFLECTION)
                .depth(JournalDepth.MEDIUM).active(true).build();
    }

    private User user(String prefix) {
        return users.save(User.builder().email(prefix + "-" + UUID.randomUUID() + "@example.com")
                .password("encoded").fullName("Người viết").journalEnabled(true).build());
    }
}
