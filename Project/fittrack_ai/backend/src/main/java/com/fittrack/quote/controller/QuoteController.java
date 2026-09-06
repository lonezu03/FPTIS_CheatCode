package com.fittrack.quote.controller;

import com.fittrack.common.dto.PageResponse;
import com.fittrack.quote.dto.QuoteDtos.*;
import com.fittrack.quote.entity.QuoteStatus;
import com.fittrack.quote.service.QuoteService;
import com.fittrack.user.entity.User;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/quotes")
@RequiredArgsConstructor
public class QuoteController {
    private final QuoteService quoteService;

    @GetMapping
    public PageResponse<QuoteResponse> getMine(
            @AuthenticationPrincipal User user,
            @RequestParam(defaultValue = "") String q,
            @RequestParam(defaultValue = "") String tag,
            @RequestParam(required = false) QuoteStatus status,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size
    ) {
        return quoteService.getMine(user, q, tag, status, page, size);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public QuoteResponse create(
            @AuthenticationPrincipal User user,
            @Valid @RequestBody QuoteRequest request
    ) {
        return quoteService.create(user, request);
    }

    @PostMapping("/check-duplicate")
    public DuplicateCheckResponse checkDuplicate(
            @AuthenticationPrincipal User user,
            @Valid @RequestBody DuplicateCheckRequest request
    ) {
        return quoteService.checkDuplicate(user, request);
    }

    @GetMapping("/today")
    public DailyQuoteResponse getToday(@AuthenticationPrincipal User user) {
        return quoteService.getToday(user);
    }

    @GetMapping("/history")
    public PageResponse<QuoteHistoryResponse> getHistory(
            @AuthenticationPrincipal User user,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "30") int size
    ) {
        return quoteService.getHistory(user, page, size);
    }

    @GetMapping("/{id}")
    public QuoteDetailResponse getDetail(
            @AuthenticationPrincipal User user,
            @PathVariable String id
    ) {
        return quoteService.getDetail(user, id);
    }

    @PutMapping("/{id}")
    public QuoteResponse update(
            @AuthenticationPrincipal User user,
            @PathVariable String id,
            @Valid @RequestBody QuoteRequest request
    ) {
        return quoteService.update(user, id, request);
    }

    @PostMapping("/{id}/archive")
    public QuoteResponse archive(
            @AuthenticationPrincipal User user,
            @PathVariable String id
    ) {
        return quoteService.archive(user, id);
    }

    @PostMapping("/{id}/restore")
    public QuoteResponse restore(
            @AuthenticationPrincipal User user,
            @PathVariable String id
    ) {
        return quoteService.restore(user, id);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(
            @AuthenticationPrincipal User user,
            @PathVariable String id
    ) {
        quoteService.delete(user, id);
    }
}
