package com.fittrack.nutrition.service;

import com.fittrack.nutrition.entity.Food;
import com.fittrack.nutrition.entity.FoodPreference;
import com.fittrack.nutrition.repository.FoodPreferenceRepository;
import com.fittrack.user.entity.User;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.LinkedHashSet;
import java.util.List;

@Service
@RequiredArgsConstructor
public class FoodUsageService {
    private final FoodPreferenceRepository repository;

    public void record(User user, List<Food> foods) {
        LocalDateTime now = LocalDateTime.now();
        for (Food food : new LinkedHashSet<>(foods)) {
            FoodPreference preference = repository.findByUserAndFoodId(user, food.getId())
                    .orElseGet(() -> FoodPreference.builder()
                            .user(user)
                            .food(food)
                            .build());
            preference.setUseCount((preference.getUseCount() == null ? 0 : preference.getUseCount()) + 1);
            preference.setLastUsedAt(now);
            repository.save(preference);
        }
    }
}
