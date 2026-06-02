package com.fittrack.achievement.controller;

import com.fittrack.achievement.dto.AchievementSummaryResponse;
import com.fittrack.achievement.service.AchievementService;
import com.fittrack.user.entity.User;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/achievements")
@RequiredArgsConstructor
public class AchievementController {

    private final AchievementService achievementService;

    @GetMapping("/summary")
    public AchievementSummaryResponse getSummary(Authentication authentication) {
        User user = (User) authentication.getPrincipal();

        return achievementService.getSummary(user);
    }
}

