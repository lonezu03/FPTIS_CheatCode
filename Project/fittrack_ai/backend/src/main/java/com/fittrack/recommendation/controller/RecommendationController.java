package com.fittrack.recommendation.controller;

import com.fittrack.recommendation.dto.WeeklyRecommendationResponse;
import com.fittrack.recommendation.service.RecommendationService;
import com.fittrack.recommendation.service.WeeklyCoachService;
import com.fittrack.recommendation.dto.WeeklyCoachDtos.CheckInDecisionRequest;
import com.fittrack.recommendation.dto.WeeklyCoachDtos.WeeklyCheckInResponse;
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
    private final WeeklyCoachService weeklyCoachService;

    @GetMapping("/weekly")
    public WeeklyRecommendationResponse getWeeklyRecommendations(
            Authentication authentication,
            @RequestParam(required = false) LocalDate fromDate,
            @RequestParam(required = false) LocalDate toDate
    ) {
        User user = (User) authentication.getPrincipal();

        return recommendationService.getWeeklyRecommendations(user, fromDate, toDate);
    }

    @GetMapping("/check-ins/current")
    public WeeklyCheckInResponse getCurrentCheckIn(
            Authentication authentication,
            @RequestParam(required = false) LocalDate weekStart
    ) {
        return weeklyCoachService.current(
                (User) authentication.getPrincipal(), weekStart
        );
    }

    @GetMapping("/check-ins")
    public java.util.List<WeeklyCheckInResponse> getCheckIns(Authentication authentication) {
        return weeklyCoachService.history((User) authentication.getPrincipal());
    }

    @org.springframework.web.bind.annotation.PostMapping("/check-ins/{id}/decision")
    public WeeklyCheckInResponse decideCheckIn(
            Authentication authentication,
            @org.springframework.web.bind.annotation.PathVariable String id,
            @org.springframework.web.bind.annotation.RequestBody CheckInDecisionRequest request
    ) {
        return weeklyCoachService.decide(
                (User) authentication.getPrincipal(), id, request.decision()
        );
    }
}
