package com.fittrack.user.service;

import com.fittrack.user.entity.User;
import org.springframework.stereotype.Service;

@Service
public class GoalCalculatorService {

    public double calculateBmr(User user) {
        double weight = user.getWeight() == null ? 60 : user.getWeight();
        double height = user.getHeight() == null ? 160 : user.getHeight();
        int age = user.getAge() == null ? 23 : user.getAge();

        if ("FEMALE".equalsIgnoreCase(user.getGender())) {
            return 10 * weight + 6.25 * height - 5 * age - 161;
        }

        return 10 * weight + 6.25 * height - 5 * age + 5;
    }

    public double calculateTdee(User user) {
        double bmr = calculateBmr(user);
        double multiplier = switch (safe(user.getActivityLevel())) {
            case "SEDENTARY" -> 1.2;
            case "LIGHT" -> 1.375;
            case "MODERATE" -> 1.55;
            case "ACTIVE" -> 1.725;
            default -> 1.375;
        };

        return bmr * multiplier;
    }

    public double calculateTargetCalories(User user) {
        double tdee = calculateTdee(user);

        return switch (safe(user.getGoal())) {
            case "CUT" -> tdee - 300;
            case "LEAN_BULK" -> tdee + 250;
            case "MAINTAIN" -> tdee;
            default -> tdee;
        };
    }

    public double calculateProtein(User user) {
        double weight = user.getWeight() == null ? 60 : user.getWeight();
        return weight * 1.8;
    }

    public double calculateFat(User user) {
        double weight = user.getWeight() == null ? 60 : user.getWeight();
        return weight * 0.8;
    }

    public double calculateCarbs(User user) {
        double calories = calculateTargetCalories(user);
        double proteinCalories = calculateProtein(user) * 4;
        double fatCalories = calculateFat(user) * 9;

        return (calories - proteinCalories - fatCalories) / 4;
    }

    private String safe(String value) {
        return value == null ? "" : value.toUpperCase();
    }
}

