package com.fittrack.schedule.controller;

import com.fittrack.schedule.dto.ScheduleDtos.ScheduleRequest;
import com.fittrack.schedule.dto.ScheduleDtos.ScheduleResponse;
import com.fittrack.schedule.service.ScheduleService;
import com.fittrack.user.entity.User;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.time.LocalDateTime;

@RestController
@RequestMapping("/api/schedule")
@RequiredArgsConstructor
public class ScheduleController {
    private final ScheduleService scheduleService;

    @GetMapping
    public List<ScheduleResponse> getMine(@AuthenticationPrincipal User user) {
        return scheduleService.getMine(user);
    }

    @GetMapping("/calendar")
    public List<com.fittrack.schedule.dto.ScheduleDtos.CalendarEntryResponse> getCalendar(
            @AuthenticationPrincipal User user,
            @RequestParam LocalDateTime from,
            @RequestParam LocalDateTime to
    ) {
        return scheduleService.getCalendar(user, from, to);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public ScheduleResponse create(@AuthenticationPrincipal User user, @Valid @RequestBody ScheduleRequest request) {
        return scheduleService.create(user, request);
    }

    @PatchMapping("/{id}")
    public ScheduleResponse update(@AuthenticationPrincipal User user, @PathVariable String id, @Valid @RequestBody ScheduleRequest request) {
        return scheduleService.update(user, id, request);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@AuthenticationPrincipal User user, @PathVariable String id) {
        scheduleService.delete(user, id);
    }
}
