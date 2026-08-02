package com.fittrack.audit.controller;

import com.fittrack.audit.entity.AuditEvent;
import com.fittrack.audit.repository.AuditEventRepository;
import com.fittrack.common.dto.PageResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/admin/audit-events")
@RequiredArgsConstructor
public class AuditController {

    private final AuditEventRepository repository;

    @GetMapping
    public PageResponse<AuditEvent> list(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size
    ) {
        int safeSize = Math.min(Math.max(size, 1), 100);
        return PageResponse.from(repository.findAllByOrderByCreatedAtDesc(
                PageRequest.of(Math.max(page, 0), safeSize)
        ));
    }
}
