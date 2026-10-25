package com.fittrack.catalogimport;

import com.fittrack.nutrition.repository.FoodRepository;
import com.fittrack.nutrition.service.FoodService;
import com.fittrack.nutrition.dto.CreateFoodRequest;
import com.fittrack.workout.dto.ExerciseResponse;
import com.fittrack.workout.dto.CreateExerciseRequest;
import com.fittrack.workout.entity.Exercise;
import com.fittrack.workout.repository.ExerciseRepository;
import com.fittrack.workout.service.ExerciseService;
import com.fittrack.user.entity.User;
import jakarta.persistence.EntityManager;
import jakarta.validation.Validation;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import tools.jackson.databind.json.JsonMapper;
import java.nio.charset.StandardCharsets;
import java.util.*;
import static org.assertj.core.api.Assertions.*;
import static org.mockito.Mockito.*;

class CatalogImportServiceTest {
    CatalogImportRepository batches=mock(CatalogImportRepository.class);
    FoodRepository foods=mock(FoodRepository.class);
    ExerciseRepository exercises=mock(ExerciseRepository.class);
    FoodService foodService=mock(FoodService.class);
    ExerciseService exerciseService=mock(ExerciseService.class);
    EntityManager em=mock(EntityManager.class);
    CatalogImportLookup lookup=mock(CatalogImportLookup.class);
    CatalogImportService service;
    User actor;Map<String,CatalogImportBatch> saved=new HashMap<>();
    @BeforeEach void setup(){
        service=new CatalogImportService(batches,exercises,foods,exerciseService,foodService,JsonMapper.builder().findAndAddModules().build(),Validation.buildDefaultValidatorFactory().getValidator(),em,mock(com.fittrack.common.media.MediaStorageService.class),lookup);
        actor=new User();actor.setId("admin");actor.setRole("ADMIN");actor.setActive(true);
        when(lookup.duplicateRows(anyString(),anyInt(),anyInt())).thenReturn(List.of());
        when(batches.save(any())).thenAnswer(i->{var b=(CatalogImportBatch)i.getArgument(0);saved.put(b.getId(),b);return b;});
        when(batches.locked(anyString(),anyString())).thenAnswer(i->Optional.ofNullable(saved.get(i.getArgument(0))).filter(b->b.getActorId().equals(i.getArgument(1))));
    }
    CatalogImportService.Batch preview(String kind,String csv){return service.preview(actor,kind,csv.getBytes(StandardCharsets.UTF_8),"x.csv",Map.of());}
    @Test void calorieMismatchWarnsWithoutRejectingLabelDataAndRecordsSourceHash(){
        var batch=preview("FOOD","name,unit,basis,calories,protein,carbs,fat\nNhãn,bát,PER_SERVING,999,1,1,1");
        assertThat(batch.rows().getFirst().errors()).isEmpty();
        assertThat(batch.rows().getFirst().warnings()).anyMatch(message->message.startsWith("Năng lượng lệch"));
        assertThat(saved.get(batch.id()).getSourceDigest()).hasSize(64);
    }
    @Test void validatesNumbersBasisAndKeepsUnknownMicros(){
        var valid=preview("FOOD","name,unit,basis,servingSizeGrams,calories,protein,carbs,fat\nCơm,bát,PER_100G,200,100,2,20,1");
        assertThat(valid.rows().getFirst().errors()).isEmpty();
        assertThat(valid.rows().getFirst().after().get("calories")).isEqualTo("200.0");
        when(foodService.create(any())).thenAnswer(i->{CreateFoodRequest r=i.getArgument(0);assertThat(r.getCalories()).isEqualTo(200);assertThat(r.getFiber()).isNull();return com.fittrack.nutrition.dto.FoodResponse.builder().id("food").build();});
        service.commit(actor,valid.id(),new CatalogImportService.Commit(List.of(new CatalogImportService.Selection(2,"CREATE",List.of()))));
        assertThat(preview("FOOD","name,unit,basis,calories,protein,carbs,fat\nx,g,PER_SERVING,NaN,1,1,1").rows().getFirst().errors()).isNotEmpty();
        assertThat(preview("FOOD","name,unit,calories,protein,carbs,fat\nx,g,10,1,1,1").rows().getFirst().errors()).isNotEmpty();
    }
    @Test void commitIsIdempotentAndBoundToActor(){
        var batch=preview("EXERCISE","name,muscleGroup,equipment\nSquat,Legs,Smith");
        when(exerciseService.create(any())).thenReturn(ExerciseResponse.builder().id("new").build());
        var request=new CatalogImportService.Commit(List.of(new CatalogImportService.Selection(2,"CREATE",List.of())));
        service.commit(actor,batch.id(),request);service.commit(actor,batch.id(),request);verify(exerciseService,times(1)).create(any(CreateExerciseRequest.class));
        User other=new User();other.setId("other");other.setRole("ADMIN");other.setActive(true);assertThatThrownBy(()->service.commit(other,batch.id(),request)).isInstanceOf(org.springframework.web.server.ResponseStatusException.class);
    }
    @Test void duplicateDefaultsToSkipAndNeverUpdatesPending(){
        Exercise existing=Exercise.builder().id("known").name("Squat").muscleGroup("Legs").equipment("Smith").approvalStatus("PENDING").active(false).build();
        when(lookup.duplicateRows(eq("EXERCISE"),anyInt(),anyInt())).thenReturn(List.of(Map.of("id","known","name","Squat","muscleGroup","Legs","equipment","Smith")));when(exercises.findById("known")).thenReturn(Optional.of(existing));
        assertThat(preview("EXERCISE","name,muscleGroup,equipment\nSquat,Legs,Smith").rows().getFirst().suggestedAction()).isEqualTo("SKIP");
        var invalid=preview("EXERCISE","id,name,muscleGroup,equipment\nknown,Squat,Legs,Smith");assertThat(invalid.rows().getFirst().errors()).isNotEmpty();
        assertThatThrownBy(()->service.commit(actor,invalid.id(),new CatalogImportService.Commit(List.of(new CatalogImportService.Selection(2,"UPDATE",List.of()))))).isInstanceOf(IllegalArgumentException.class);
    }
    @Test void missingAdminRejected(){actor.setRole("USER");assertThatThrownBy(()->preview("EXERCISE","name\nx")).isInstanceOf(org.springframework.web.server.ResponseStatusException.class);}
    @Test void updatePreservesBlankFieldsAndDetectsConcurrentChanges(){
        Exercise existing=Exercise.builder().id("known").name("Squat").muscleGroup("Legs").equipment("Smith").description("Keep instructions").imageUrl("data:image/png;base64,old").approvalStatus("APPROVED").active(true).build();
        when(exercises.findAll()).thenReturn(List.of(existing));when(exercises.findById("known")).thenReturn(Optional.of(existing));
        var first=preview("EXERCISE","id,name,muscleGroup,equipment,description,imageUrl\nknown,New Squat,,,,");
        assertThat(first.rows().getFirst().errors()).isEmpty();
        when(exerciseService.update(eq("known"),any())).thenAnswer(i->{com.fittrack.workout.dto.UpdateExerciseRequest r=i.getArgument(1);assertThat(r.getDescription()).isEqualTo("Keep instructions");assertThat(r.getImageUrl()).isEqualTo(com.fittrack.common.media.ImageReferences.exercisePath("known"));return ExerciseResponse.builder().id("known").build();});
        service.commit(actor,first.id(),new CatalogImportService.Commit(List.of(new CatalogImportService.Selection(2,"UPDATE",List.of()))));
        var stale=preview("EXERCISE","id,name\nknown,Other Squat");existing.setName("Concurrent change");
        assertThatThrownBy(()->service.commit(actor,stale.id(),new CatalogImportService.Commit(List.of(new CatalogImportService.Selection(2,"UPDATE",List.of()))))).isInstanceOf(org.springframework.web.server.ResponseStatusException.class);
    }
    @Test void duplicatesCanonicalizeAliasesUnicodeAndNumericWeightsWithoutLoadingCatalogEntities(){
        when(lookup.duplicateRows(eq("EXERCISE"),anyInt(),anyInt())).thenReturn(List.of(Map.of("id","existing","name","Press","muscleGroup","Chest","equipment","Dumbbell")));
        assertThat(preview("EXERCISE","name,muscleGroup,equipment\nＰｒｅｓｓ,Ngực,tạ đơn").rows().getFirst().suggestedAction()).isEqualTo("SKIP");
        when(lookup.duplicateRows(eq("FOOD"),anyInt(),anyInt())).thenReturn(List.of(Map.of("id","existing","name","Cơm trắng","unit","bát","servingSizeGrams","100.0")));
        assertThat(preview("FOOD","name,unit,basis,servingSizeGrams,calories,protein,carbs,fat\nCơm  trắng,bát,PER_SERVING,100,100,2,20,1").rows().getFirst().suggestedAction()).isEqualTo("SKIP");
        verify(exercises,never()).findAll();verify(foods,never()).findAll();
    }
    @Test void updateDuplicateCheckUsesMergedValuesAndDoesNotFlagItself(){
        Exercise existing=Exercise.builder().id("known").name("Squat").muscleGroup("Legs").equipment("Smith").approvalStatus("APPROVED").active(true).build();
        when(exercises.findById("known")).thenReturn(Optional.of(existing));
        when(lookup.duplicateRows(eq("EXERCISE"),anyInt(),anyInt())).thenReturn(List.of(Map.of("id","known","name","Squat","muscleGroup","Legs","equipment","Smith Machine")));
        assertThat(preview("EXERCISE","id,name\nknown,Squat").rows().getFirst().warnings()).isEmpty();
        when(lookup.duplicateRows(eq("EXERCISE"),anyInt(),anyInt())).thenReturn(List.of(Map.of("id","different","name","New squat","muscleGroup","Legs","equipment","Smith Machine")));
        assertThat(preview("EXERCISE","id,name\nknown,New squat").rows().getFirst().suggestedAction()).isEqualTo("SKIP");
    }
    @Test void newlyAppearedDuplicateRequiresNewPreviewButAcceptedWarningDoesNot(){
        var batch=preview("EXERCISE","name,muscleGroup,equipment\nPress,Ngực,tạ đơn");
        assertThat(batch.rows().getFirst().after()).containsEntry("muscleGroup","Chest").containsEntry("equipment","Dumbbell");
        when(lookup.duplicateRows(eq("EXERCISE"),anyInt(),anyInt())).thenReturn(List.of(Map.of("id","new-other","name","Press","muscleGroup","Chest","equipment","Dumbbell")));
        var selection=new CatalogImportService.Commit(List.of(new CatalogImportService.Selection(2,"CREATE",List.of())));
        assertThatThrownBy(()->service.commit(actor,batch.id(),selection)).isInstanceOf(org.springframework.web.server.ResponseStatusException.class).hasMessageContaining("409");
        verify(exerciseService,never()).create(any());
        var accepted=preview("EXERCISE","name,muscleGroup,equipment\nPress,Ngực,tạ đơn");
        when(exerciseService.create(any())).thenReturn(ExerciseResponse.builder().id("explicit-duplicate").build());
        assertThat(service.commit(actor,accepted.id(),selection).rows().getFirst().resultId()).isEqualTo("explicit-duplicate");
    }
    @Test void unknownHeadersRequireMappingOrExplicitIgnore(){
        String csv="name,muscleGroup,equipment,unexpected\nPress,Chest,Dumbbell,not silently dropped";
        assertThatThrownBy(()->preview("EXERCISE",csv)).isInstanceOf(IllegalArgumentException.class).hasMessageContaining("unexpected");
        var mapped=service.preview(actor,"EXERCISE",csv.getBytes(StandardCharsets.UTF_8),"x.csv",Map.of("unexpected","__IGNORE__"));
        assertThat(mapped.rows().getFirst().errors()).isEmpty();
    }
}
