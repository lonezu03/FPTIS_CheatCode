package com.fittrack.quote.controller;

import com.fittrack.quote.service.QuoteService;
import com.fittrack.user.entity.User;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/quote-tags")
@RequiredArgsConstructor
public class QuoteTagController {
    private final QuoteService quoteService;

    @GetMapping
    public List<String> getMine(@AuthenticationPrincipal User user) {
        return quoteService.getTags(user);
    }
}
