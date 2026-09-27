package com.fittrack.journal.controller;

import com.fittrack.common.dto.PageResponse;
import com.fittrack.journal.dto.JournalDtos.*;
import com.fittrack.journal.service.JournalService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.*;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/admin/journal/prompts")
@RequiredArgsConstructor
public class AdminJournalPromptController {
    private final JournalService service;

    @GetMapping public PageResponse<PromptResponse> list(@RequestParam(defaultValue = "") String q,
            @RequestParam(required = false) Boolean active, @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) { return service.adminPrompts(q, active, page, size); }
    @PostMapping @ResponseStatus(HttpStatus.CREATED)
    public PromptResponse create(@Valid @RequestBody AdminPromptRequest request) { return service.createPrompt(request); }
    @PutMapping("/{id}") public PromptResponse update(@PathVariable String id, @Valid @RequestBody AdminPromptRequest request) { return service.updatePrompt(id, request); }
}
