package com.fittrack.recommendation.controller;

import com.fittrack.recommendation.dto.WeeklyRecommendationResponse;
import com.fittrack.recommendation.service.RecommendationService;
import com.fittrack.user.entity.User;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDate;

@RestController
@RequestMapping("/api/recommendations")
@RequiredArgsConstructor
public class RecommendationController {

    private final RecommendationService recommendationService;

    @GetMapping("/weekly")
    public WeeklyRecommendationResponse getWeeklyRecommendations(
            Authentication authentication,
            @RequestParam(required = false) LocalDate fromDate,
            @RequestParam(required = false) LocalDate toDate
    ) {
        User user = (User) authentication.getPrincipal();

        return recommendationService.getWeeklyRecommendations(user, fromDate, toDate);
    }
}
