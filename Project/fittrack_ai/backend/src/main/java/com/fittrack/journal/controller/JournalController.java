package com.fittrack.journal.controller;

import com.fittrack.common.dto.PageResponse;
import com.fittrack.journal.dto.JournalDtos.*;
import com.fittrack.journal.entity.*;
import com.fittrack.journal.service.JournalService;
import com.fittrack.user.entity.User;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.*;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/journal")
@RequiredArgsConstructor
public class JournalController {
    private final JournalService service;

    @GetMapping("/today") public TodayResponse today(@AuthenticationPrincipal User user) { return service.today(user); }
    @PostMapping("/today/skip") public TodayResponse skip(@AuthenticationPrincipal User user) { return service.skipToday(user); }

    @GetMapping("/entries")
    public PageResponse<EntryResponse> entries(@AuthenticationPrincipal User user,
            @RequestParam(defaultValue = "") String q, @RequestParam(required = false) JournalOrigin origin,
            @RequestParam(defaultValue = "0") int page, @RequestParam(defaultValue = "20") int size) {
        return service.list(user, q, origin, page, size);
    }
    @PostMapping("/entries") @ResponseStatus(HttpStatus.CREATED)
    public EntryResponse create(@AuthenticationPrincipal User user, @Valid @RequestBody EntryRequest request) { return service.create(user, request); }
    @GetMapping("/entries/{id}") public EntryResponse get(@AuthenticationPrincipal User user, @PathVariable String id) { return service.get(user, id); }
    @PutMapping("/entries/{id}") public EntryResponse update(@AuthenticationPrincipal User user, @PathVariable String id, @Valid @RequestBody EntryRequest request) { return service.update(user, id, request); }
    @DeleteMapping("/entries/{id}") @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@AuthenticationPrincipal User user, @PathVariable String id) { service.delete(user, id); }

    @GetMapping("/prompts")
    public PageResponse<PromptResponse> prompts(@RequestParam(defaultValue = "") String q,
            @RequestParam(required = false) JournalCategory category, @RequestParam(required = false) JournalDepth depth,
            @RequestParam(defaultValue = "0") int page, @RequestParam(defaultValue = "20") int size) {
        return service.promptLibrary(q, category, depth, page, size);
    }
    @GetMapping("/settings") public ReminderSettingsResponse settings(@AuthenticationPrincipal User user) { return service.getSettings(user); }
    @PutMapping("/settings") public ReminderSettingsResponse settings(@AuthenticationPrincipal User user, @Valid @RequestBody ReminderSettingsRequest request) { return service.updateSettings(user, request); }
}
