package com.fittrack.journal.service;

import com.fittrack.common.dto.PageResponse;
import com.fittrack.common.exception.*;
import com.fittrack.journal.dto.JournalDtos.*;
import com.fittrack.journal.entity.*;
import com.fittrack.journal.repository.*;
import com.fittrack.lunch.service.LunchNotificationService;
import com.fittrack.user.entity.User;
import com.fittrack.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.PageRequest;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.*;
import java.util.*;
import java.util.concurrent.ThreadLocalRandom;

@Service
@RequiredArgsConstructor
public class JournalService {
    private static final ZoneId ZONE = ZoneId.of("Asia/Ho_Chi_Minh");
    private static final LocalTime DEFAULT_REMINDER = LocalTime.of(21, 30);

    private final JournalPromptRepository prompts;
    private final JournalPromptDisplayRepository displays;
    private final JournalEntryRepository entries;
    private final JournalSettingsRepository settings;
    private final UserRepository users;
    private final LunchNotificationService notifications;

    @Value("${app.scheduler.internal-enabled:true}")
    private boolean schedulerEnabled;

    @Transactional
    public TodayResponse today(User principal) {
        User user = lockedUser(principal);
        LocalDate today = LocalDate.now(ZONE);
        JournalPromptDisplay display = displays.findFirstByUserAndDisplayDateOrderByCreatedAtDesc(user, today)
                .orElseGet(() -> assign(user, today, null));
        return todayResponse(display);
    }

    @Transactional
    public TodayResponse skipToday(User principal) {
        User user = lockedUser(principal);
        LocalDate today = LocalDate.now(ZONE);
        JournalPromptDisplay current = displays.findFirstByUserAndDisplayDateOrderByCreatedAtDesc(user, today)
                .orElseGet(() -> assign(user, today, null));
        if (current.getStatus() == JournalDisplayStatus.ANSWERED) {
            throw new ConflictException("Câu hỏi hôm nay đã được trả lời");
        }
        current.setStatus(JournalDisplayStatus.SKIPPED);
        current.setSkippedAt(LocalDateTime.now(ZONE));
        displays.save(current);
        return todayResponse(assign(user, today, current.getPrompt().getId()));
    }

    @Transactional(readOnly = true)
    public PageResponse<EntryResponse> list(User user, String q, JournalOrigin origin, int page, int size) {
        return PageResponse.from(entries.search(user, clean(q), origin,
                PageRequest.of(Math.max(page, 0), Math.min(Math.max(size, 1), 100))).map(this::entryResponse));
    }

    @Transactional(readOnly = true)
    public EntryResponse get(User user, String id) { return entryResponse(owned(user, id)); }

    @Transactional
    public EntryResponse create(User principal, EntryRequest request) {
        User user = users.findById(principal.getId()).orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy tài khoản"));
        JournalEntry entry = JournalEntry.builder().user(user).entryDate(
                request.entryDate() == null ? LocalDate.now(ZONE) : request.entryDate())
                .origin(request.origin()).title(optional(request.title())).body(request.body().trim()).mood(request.mood()).build();
        if (request.origin() == JournalOrigin.PROMPT) {
            if (request.promptId() == null || request.promptId().isBlank()) throw new IllegalArgumentException("Vui lòng chọn câu hỏi nhật ký");
            LocalDate today = LocalDate.now(ZONE);
            JournalPromptDisplay display = displays.findFirstByUserAndDisplayDateOrderByCreatedAtDesc(user, today)
                    .filter(d -> d.getPrompt().getId().equals(request.promptId()))
                    .orElseThrow(() -> new ConflictException("Câu hỏi này không phải câu hỏi đang được giao hôm nay"));
            if (display.getStatus() == JournalDisplayStatus.ANSWERED || entries.findByPromptDisplayAndArchivedAtIsNull(display).isPresent())
                throw new ConflictException("Câu hỏi hôm nay đã được trả lời");
            entry.setEntryDate(today);
            entry.setPrompt(display.getPrompt());
            entry.setPromptDisplay(display);
            display.setStatus(JournalDisplayStatus.ANSWERED);
            display.setAnsweredAt(LocalDateTime.now(ZONE));
        } else if (request.promptId() != null && !request.promptId().isBlank()) {
            throw new IllegalArgumentException("Nhật ký tự do không gắn với câu hỏi");
        }
        return entryResponse(entries.save(entry));
    }

    @Transactional
    public EntryResponse update(User user, String id, EntryRequest request) {
        JournalEntry entry = owned(user, id);
        if (request.origin() != entry.getOrigin()) throw new IllegalArgumentException("Không thể đổi loại bài viết");
        entry.setEntryDate(entry.getOrigin() == JournalOrigin.PROMPT ? entry.getEntryDate() :
                (request.entryDate() == null ? entry.getEntryDate() : request.entryDate()));
        entry.setTitle(optional(request.title()));
        entry.setBody(request.body().trim());
        entry.setMood(request.mood());
        return entryResponse(entries.save(entry));
    }

    @Transactional
    public void delete(User user, String id) {
        JournalEntry entry = owned(user, id);
        JournalPromptDisplay display = entry.getPromptDisplay();
        entries.delete(entry);
        entries.flush();
        if (display != null) {
            display.setStatus(JournalDisplayStatus.ASSIGNED);
            display.setAnsweredAt(null);
        }
    }

    @Transactional(readOnly = true)
    public PageResponse<PromptResponse> promptLibrary(String q, JournalCategory category, JournalDepth depth, int page, int size) {
        return PageResponse.from(prompts.searchActive(clean(q), category, depth,
                PageRequest.of(Math.max(page, 0), Math.min(Math.max(size, 1), 100))).map(this::promptResponse));
    }

    @Transactional(readOnly = true)
    public ReminderSettingsResponse getSettings(User user) {
        return settings.findById(user.getId()).map(s -> new ReminderSettingsResponse(
                Boolean.TRUE.equals(s.getReminderEnabled()), s.getReminderTime()))
                .orElse(new ReminderSettingsResponse(false, DEFAULT_REMINDER));
    }

    @Transactional
    public ReminderSettingsResponse updateSettings(User user, ReminderSettingsRequest request) {
        if (Boolean.TRUE.equals(request.reminderEnabled()) && request.reminderTime() == null)
            throw new IllegalArgumentException("Vui lòng chọn giờ nhắc");
        JournalSettings value = settings.findById(user.getId()).orElseGet(() -> JournalSettings.builder().user(user).build());
        value.setReminderEnabled(request.reminderEnabled());
        value.setReminderTime(request.reminderTime() == null ? DEFAULT_REMINDER : request.reminderTime().withSecond(0).withNano(0));
        value = settings.save(value);
        return new ReminderSettingsResponse(Boolean.TRUE.equals(value.getReminderEnabled()), value.getReminderTime());
    }

    @Transactional(readOnly = true)
    public PageResponse<PromptResponse> adminPrompts(String q, Boolean active, int page, int size) {
        return PageResponse.from(prompts.searchAdmin(clean(q), active,
                PageRequest.of(Math.max(page, 0), Math.min(Math.max(size, 1), 100))).map(this::promptResponse));
    }

    @Transactional
    public PromptResponse createPrompt(AdminPromptRequest request) {
        return promptResponse(prompts.save(JournalPrompt.builder().content(request.content().trim())
                .category(request.category()).depth(request.depth()).active(request.active() == null || request.active()).build()));
    }

    @Transactional
    public PromptResponse updatePrompt(String id, AdminPromptRequest request) {
        JournalPrompt p = prompts.findById(id).orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy câu hỏi"));
        p.setContent(request.content().trim()); p.setCategory(request.category()); p.setDepth(request.depth());
        if (request.active() != null) p.setActive(request.active());
        return promptResponse(prompts.save(p));
    }

    @Scheduled(cron = "0 * * * * *", zone = "Asia/Ho_Chi_Minh")
    @Transactional
    public void sendReminders() {
        if (!schedulerEnabled) return;
        LocalDateTime now = LocalDateTime.now(ZONE).withSecond(0).withNano(0);
        for (JournalSettings setting : settings.findByReminderEnabledTrue()) {
            User user = setting.getUser();
            if (!setting.getReminderTime().equals(now.toLocalTime()) || !Boolean.TRUE.equals(user.getActive())
                    || (!"ADMIN".equalsIgnoreCase(user.getRole()) && !Boolean.TRUE.equals(user.getJournalEnabled()))) continue;
            notifications.notifyUserOnce(user, "JOURNAL_REMINDER", "Một phút dành cho bạn",
                    "Câu hỏi nhật ký hôm nay đang chờ bạn ghi lại một điều đáng nhớ.",
                    "JOURNAL", null, "journal-reminder:" + user.getId() + ":" + now.toLocalDate());
        }
    }

    private JournalPromptDisplay assign(User user, LocalDate date, String excludedId) {
        List<JournalPrompt> active = prompts.findByActiveTrueOrderByCreatedAtAsc();
        if (active.isEmpty()) throw new ResourceNotFoundException("Chưa có câu hỏi nhật ký đang hoạt động");
        int cycle = Math.max(displays.findCurrentCycle(user), 1);
        Set<String> used = displays.findPromptIdsInCycle(user, cycle);
        List<JournalPrompt> candidates = active.stream().filter(p -> !used.contains(p.getId())).toList();
        if (candidates.isEmpty()) { cycle++; candidates = active; }
        if (excludedId != null && candidates.size() > 1)
            candidates = candidates.stream().filter(p -> !p.getId().equals(excludedId)).toList();
        if (excludedId != null && candidates.size() == 1 && candidates.get(0).getId().equals(excludedId))
            throw new ConflictException("Chưa có câu hỏi khác để đổi");
        JournalPrompt selected = candidates.get(ThreadLocalRandom.current().nextInt(candidates.size()));
        return displays.save(JournalPromptDisplay.builder().user(user).prompt(selected).displayDate(date)
                .cycleNumber(cycle).status(JournalDisplayStatus.ASSIGNED).build());
    }

    private User lockedUser(User user) { return users.findByIdForUpdate(user.getId()).orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy tài khoản")); }
    private JournalEntry owned(User user, String id) { return entries.findByIdAndUserAndArchivedAtIsNull(id, user).orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy bài nhật ký")); }
    private TodayResponse todayResponse(JournalPromptDisplay d) { JournalEntry e = entries.findByPromptDisplayAndArchivedAtIsNull(d).orElse(null); return new TodayResponse(d.getDisplayDate(), promptResponse(d.getPrompt()), e != null, e == null ? null : entryResponse(e)); }
    private PromptResponse promptResponse(JournalPrompt p) { return new PromptResponse(p.getId(), p.getContent(), p.getCategory(), p.getDepth(), Boolean.TRUE.equals(p.getActive())); }
    private EntryResponse entryResponse(JournalEntry e) { return new EntryResponse(e.getId(), e.getEntryDate(), e.getOrigin(), e.getPrompt() == null ? null : promptResponse(e.getPrompt()), e.getTitle(), e.getBody(), e.getMood(), e.getCreatedAt(), e.getUpdatedAt()); }
    private static String clean(String s) { return s == null ? "" : s.trim(); }
    private static String optional(String s) { return s == null || s.isBlank() ? null : s.trim(); }
}
