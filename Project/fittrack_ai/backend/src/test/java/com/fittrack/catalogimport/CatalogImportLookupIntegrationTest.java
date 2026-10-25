package com.fittrack.catalogimport;

import com.fittrack.FittrackBackendApplication;
import com.fittrack.workout.entity.Exercise;
import com.fittrack.workout.repository.ExerciseRepository;
import com.fittrack.nutrition.entity.Food;
import com.fittrack.nutrition.repository.FoodRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;
import static org.assertj.core.api.Assertions.*;

@SpringBootTest(classes=FittrackBackendApplication.class) @ActiveProfiles("test") @Transactional
class CatalogImportLookupIntegrationTest {
    @Autowired CatalogImportLookup lookup;
    @Autowired ExerciseRepository exercises;
    @Autowired FoodRepository foods;
    @Autowired CatalogImportService service;
    @Test void scalarQueriesNeverReturnEmbeddedImagesAndExportIsApprovalScoped(){
        var exercise=exercises.saveAndFlush(Exercise.builder().name("Projection test").muscleGroup("Chest").equipment("Smith").imageUrl("data:image/png;base64,"+"A".repeat(50000)).active(true).approvalStatus("APPROVED").build());
        var food=foods.saveAndFlush(Food.builder().name("Projection food").unit("100 g").servingSizeGrams(100.0).imageUrl("data:image/png;base64,"+"B".repeat(50000)).active(true).approvalStatus("APPROVED").build());
        var exerciseRows=lookup.duplicateRows("EXERCISE",0,1000);
        assertThat(exerciseRows).anySatisfy(row->{assertThat(row.get("id")).isEqualTo(exercise.getId());assertThat(row).doesNotContainKey("imageUrl");});
        var foodRows=lookup.exportRows("FOOD",service.columns("FOOD"),0,1000);
        assertThat(foodRows).anySatisfy(row->{assertThat(row.get("id")).isEqualTo(food.getId());assertThat(row.get("imageUrl")).isEmpty();assertThat(row.get("basis")).isEqualTo("PER_SERVING");});
        exercise.setActive(false);exercises.saveAndFlush(exercise);
        assertThat(lookup.exportRows("EXERCISE",service.columns("EXERCISE"),0,1000)).noneMatch(row->exercise.getId().equals(row.get("id")));
    }
}
