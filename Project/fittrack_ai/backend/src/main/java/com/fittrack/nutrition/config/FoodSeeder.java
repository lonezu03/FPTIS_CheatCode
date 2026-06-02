package com.fittrack.nutrition.config;

import com.fittrack.nutrition.entity.Food;
import com.fittrack.nutrition.repository.FoodRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
public class FoodSeeder implements CommandLineRunner {

    private final FoodRepository foodRepository;

    @Override
    public void run(String... args) {
        if (foodRepository.count() > 0) return;

        foodRepository.save(Food.builder()
                .name("Chicken Breast")
                .calories(165.0)
                .protein(31.0)
                .carbs(0.0)
                .fat(3.6)
                .unit("100g")
                .custom(false)
                .active(true)
                .build());

        foodRepository.save(Food.builder()
                .name("White Rice")
                .calories(130.0)
                .protein(2.7)
                .carbs(28.0)
                .fat(0.3)
                .unit("100g")
                .custom(false)
                .active(true)
                .build());

        foodRepository.save(Food.builder()
                .name("Egg")
                .calories(70.0)
                .protein(6.0)
                .carbs(0.6)
                .fat(5.0)
                .unit("1 egg")
                .custom(false)
                .active(true)
                .build());

        foodRepository.save(Food.builder()
                .name("Sweet Potato")
                .calories(86.0)
                .protein(1.6)
                .carbs(20.0)
                .fat(0.1)
                .unit("100g")
                .custom(false)
                .active(true)
                .build());
    }
}

