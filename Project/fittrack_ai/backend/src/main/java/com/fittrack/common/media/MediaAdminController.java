package com.fittrack.common.media;

import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/admin/media")
@RequiredArgsConstructor
public class MediaAdminController {

    private final MediaMigrationService migrationService;

    @PostMapping("/migrate")
    public MediaMigrationService.MigrationResult migrate(
            @RequestParam(defaultValue = "25") int limit
    ) {
        return migrationService.migrate(limit);
    }
}
