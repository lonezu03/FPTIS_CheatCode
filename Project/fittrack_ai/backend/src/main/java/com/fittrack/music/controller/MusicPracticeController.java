package com.fittrack.music.controller;

import com.fittrack.common.dto.PageResponse;
import com.fittrack.music.dto.MusicDtos.*;
import com.fittrack.music.entity.MusicInstrument;
import com.fittrack.music.service.MusicPracticeService;
import com.fittrack.user.entity.User;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;

@RestController
@RequestMapping("/api/music")
@RequiredArgsConstructor
public class MusicPracticeController {
    private final MusicPracticeService service;

    @PostMapping("/sessions")
    @ResponseStatus(HttpStatus.CREATED)
    public SessionResponse create(@AuthenticationPrincipal User user,
                                  @Valid @RequestBody CreateSessionRequest request) {
        return service.create(user, request);
    }

    @GetMapping("/sessions")
    public PageResponse<SessionResponse> list(
            @AuthenticationPrincipal User user,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to,
            @RequestParam(required = false) MusicInstrument instrument,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        return service.list(user, from, to, instrument, page, size);
    }

    @DeleteMapping("/sessions/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@AuthenticationPrincipal User user, @PathVariable String id) {
        service.delete(user, id);
    }

    @GetMapping("/summary")
    public SummaryResponse summary(@AuthenticationPrincipal User user) {
        return service.summary(user);
    }
}
