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
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertNull;

@SpringBootTest(classes = FittrackBackendApplication.class)
@ActiveProfiles("test")
@Transactional
class CatalogSeederIntegrationTest {

    @Autowired private ExerciseSeeder exerciseSeeder;
    @Autowired private FoodSeeder foodSeeder;
    @Autowired private ExerciseRepository exerciseRepository;
    @Autowired private FoodRepository foodRepository;
    @Autowired private com.fittrack.nutrition.service.FoodService foodService;
    @Autowired private com.fittrack.workout.service.ExerciseService exerciseService;
    @Autowired private com.fittrack.nutrition.mapper.NutritionMapper nutritionMapper;
    @Autowired private com.fittrack.nutrition.service.NutritionService nutritionService;
    @Autowired private com.fittrack.user.repository.UserRepository userRepository;

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

    @Test
    void stableSeedKeysPreserveRenamedArchivedAndCuratedRows() {
        var exercise = exerciseRepository.findAll().stream().filter(value -> "Barbell Bench Press".equals(value.getName())).findFirst().orElseThrow();
        var food = foodRepository.findAll().stream().filter(value -> "Chuối".equals(value.getName())).findFirst().orElseThrow();
        long exercisesBefore = exerciseRepository.count();
        long foodsBefore = foodRepository.count();
        exercise.setName("Bài ngực do admin biên tập");
        exercise.setDescription("Hướng dẫn riêng\n" + "a".repeat(1500));
        exercise.setActive(false);
        food.setName("Chuối theo nhãn thực tế");
        food.setCalories(123.0);
        food.setFiber(null);
        food.setActive(false);
        exerciseRepository.saveAndFlush(exercise);
        foodRepository.saveAndFlush(food);
        exerciseSeeder.run();
        foodSeeder.run();
        assertEquals(exercisesBefore, exerciseRepository.count());
        assertEquals(foodsBefore, foodRepository.count());
        assertEquals("Bài ngực do admin biên tập", exerciseRepository.findById(exercise.getId()).orElseThrow().getName());
        assertFalse(exerciseRepository.findById(exercise.getId()).orElseThrow().getActive());
        assertEquals(123.0, foodRepository.findById(food.getId()).orElseThrow().getCalories());
        assertFalse(foodRepository.findById(food.getId()).orElseThrow().getActive());
    }

    @Test
    void catalogSearchMatchesAllLiteralAccentInsensitiveTokensAndRestrictsApproval() {
        var approved = com.fittrack.workout.entity.Exercise.builder().name("Đẩy ngực tạ đơn thử").muscleGroup("Chest").equipment("Dumbbell").description("Hạ chậm").active(true).approvalStatus("APPROVED").build();
        var pending = com.fittrack.workout.entity.Exercise.builder().name("Đẩy ngực tạ đơn chưa duyệt").muscleGroup("Chest").equipment("Dumbbell").active(true).approvalStatus("PENDING").build();
        exerciseRepository.saveAndFlush(approved);
        exerciseRepository.saveAndFlush(pending);
        var results = exerciseService.getExercisesPage("cham day", false, 0, 20, "Chest", "Dumbbell");
        assertTrue(results.content().stream().anyMatch(value -> value.getId().equals(approved.getId())));
        assertTrue(results.content().stream().noneMatch(value -> value.getId().equals(pending.getId())));
        assertThrows(IllegalArgumentException.class, () -> exerciseService.restore(pending.getId()));
        var food = com.fittrack.nutrition.entity.Food.builder().name("Sữa chua tươi kiểm tra").unit("100g").active(true).approvalStatus("APPROVED").build();
        foodRepository.saveAndFlush(food);
        assertTrue(foodService.getFoodsPage("tuoi sua", false, 0, 100).content().stream().anyMatch(value -> food.getId().equals(value.getId())));
    }

    @Test
    void historicalMealLabelsRemainStableWhenCatalogChanges() {
        var food = com.fittrack.nutrition.entity.Food.builder().id("test").name("Tên lúc ghi").unit("100g").dataSourceName("Nhãn cũ").servingSizeGrams(100.0).build();
        var mealItem = com.fittrack.nutrition.entity.MealItem.builder().food(food).calories(100.0).build();
        mealItem.snapshotFood();
        food.setName("Tên mới");
        food.setUnit("1 phần");
        food.setDataSourceName("Nguồn mới");
        var response = nutritionMapper.toMealItemResponse(mealItem);
        assertEquals("Tên lúc ghi", response.getFoodName());
        assertEquals("100g", response.getFoodUnit());
        assertEquals("Nhãn cũ", response.getFoodSourceName());
        assertEquals(100.0, response.getCalories());
    }

    @Test
    void volumePortionsDoNotInventGramWeightsOrCrossConvertDensity() {
        var user = userRepository.save(com.fittrack.user.entity.User.builder().email("volume-" + java.util.UUID.randomUUID() + "@example.com").password("encoded").fullName("Volume test").role("USER").active(true).build());
        var food = foodRepository.saveAndFlush(com.fittrack.nutrition.entity.Food.builder().name("Sữa thử").unit("100ml").servingSizeGrams(100.0).calories(60.0).protein(3.0).carbs(4.0).fat(3.0).build());
        var item = new com.fittrack.nutrition.dto.CreateMealItemRequest();
        item.setFoodId(food.getId()); item.setServingAmount(150.0); item.setServingUnit("ML");
        var request = new com.fittrack.nutrition.dto.CreateMealLogRequest();
        request.setMealType("BREAKFAST"); request.setLogDate(java.time.LocalDate.of(2026, 10, 25)); request.setItems(java.util.List.of(item));
        var meal = nutritionService.createMealLog(user, request);
        assertEquals(90.0, meal.getTotalCalories());
        assertNull(meal.getItems().getFirst().getGramsEquivalent());
        food.setName("Sữa đổi tên"); foodRepository.saveAndFlush(food);
        assertEquals("Sữa thử", nutritionService.getMyMealLogs(user).getFirst().getItems().getFirst().getFoodName());
        food.setCalories(120.0);
        food.setDataSourceName("Nhãn cập nhật");
        foodRepository.saveAndFlush(food);
        var updateItem = new com.fittrack.nutrition.dto.UpdateMealItemRequest();
        updateItem.setFoodId(food.getId()); updateItem.setServingAmount(150.0); updateItem.setServingUnit("ML");
        var updateRequest = new com.fittrack.nutrition.dto.UpdateMealLogRequest();
        updateRequest.setMealType("BREAKFAST"); updateRequest.setLogDate(request.getLogDate()); updateRequest.setItems(java.util.List.of(updateItem));
        var updated = nutritionService.updateMealLog(user, meal.getId(), updateRequest);
        assertEquals(180.0, updated.getTotalCalories());
        assertEquals("Sữa đổi tên", updated.getItems().getFirst().getFoodName());
        assertEquals("Nhãn cập nhật", updated.getItems().getFirst().getFoodSourceName());
        assertNull(updated.getItems().getFirst().getGramsEquivalent());
        item.setServingUnit("GRAM");
        assertThrows(IllegalArgumentException.class, () -> nutritionService.createMealLog(user, request));
    }
}
