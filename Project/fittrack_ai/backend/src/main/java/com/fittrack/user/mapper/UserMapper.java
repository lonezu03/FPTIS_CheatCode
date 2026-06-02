package com.fittrack.user.mapper;

import com.fittrack.user.dto.UserProfileResponse;
import com.fittrack.user.entity.User;
import com.fittrack.user.service.GoalCalculatorService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
public class UserMapper {

    private final GoalCalculatorService goalCalculatorService;

    public UserProfileResponse toProfileResponse(User user) {
        return UserProfileResponse.builder()
                .id(user.getId())
                .email(user.getEmail())
                .fullName(user.getFullName())
                .gender(user.getGender())
                .age(user.getAge())
                .height(user.getHeight())
                .weight(user.getWeight())
                .goal(user.getGoal())
                .activityLevel(user.getActivityLevel())
                .bmr(round(goalCalculatorService.calculateBmr(user)))
                .tdee(round(goalCalculatorService.calculateTdee(user)))
                .targetCalories(round(goalCalculatorService.calculateTargetCalories(user)))
                .targetProtein(round(goalCalculatorService.calculateProtein(user)))
                .targetCarbs(round(goalCalculatorService.calculateCarbs(user)))
                .targetFat(round(goalCalculatorService.calculateFat(user)))
                .build();
    }

    private double round(double value) {
        return Math.round(value * 10.0) / 10.0;
    }
}

