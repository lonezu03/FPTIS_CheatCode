package com.fittrack.catalog;

import com.fittrack.FittrackBackendApplication;
import com.fittrack.nutrition.config.FoodSeeder;
import com.fittrack.nutrition.repository.FoodRepository;
import com.fittrack.workout.config.ExerciseSeeder;
import com.fittrack.workout.repository.ExerciseRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

@SpringBootTest(classes = FittrackBackendApplication.class)
@ActiveProfiles("test")
@Transactional
class CatalogSeederIntegrationTest {

    @Autowired private ExerciseSeeder exerciseSeeder;
    @Autowired private FoodSeeder foodSeeder;
    @Autowired private ExerciseRepository exerciseRepository;
    @Autowired private FoodRepository foodRepository;

    @Test
    void gymCatalogUpsertIsIdempotentAndPreservesCuratedImage() throws Exception {
        var benchPress = exerciseRepository.findAll().stream()
                .filter(value -> "Barbell Bench Press".equals(value.getName()))
                .findFirst().orElseThrow();
        benchPress.setImageUrl("https://example.com/bench-press.jpg");
        exerciseRepository.saveAndFlush(benchPress);
        long before = exerciseRepository.count();

        exerciseSeeder.run();
        exerciseSeeder.run();

        var reloaded = exerciseRepository.findById(benchPress.getId()).orElseThrow();
        assertEquals(before, exerciseRepository.count());
        assertEquals("https://example.com/bench-press.jpg", reloaded.getImageUrl());
        assertEquals("Chest", reloaded.getMuscleGroup());
        assertTrue(reloaded.getDescription().contains("bả vai"));
    }

    @Test
    void foodCatalogAddsMicronutrientsWithoutCreatingDuplicates() throws Exception {
        long before = foodRepository.count();

        foodSeeder.run();
        foodSeeder.run();

        var banana = foodRepository.findAll().stream()
                .filter(value -> "Chuối".equals(value.getName()))
                .findFirst().orElseThrow();
        assertEquals(before, foodRepository.count());
        assertNotNull(banana.getFiber());
        assertNotNull(banana.getPotassium());
        assertNotNull(banana.getVitaminC());
        assertEquals("ESTIMATED", banana.getDataSourceType());
    }
}
