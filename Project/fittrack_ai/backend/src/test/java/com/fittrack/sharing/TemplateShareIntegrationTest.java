package com.fittrack.sharing;

import com.fittrack.FittrackBackendApplication;
import com.fittrack.user.entity.User;
import com.fittrack.user.repository.UserRepository;
import com.fittrack.workout.entity.Exercise;
import com.fittrack.workout.repository.ExerciseRepository;
import com.fittrack.workoutplan.dto.*;
import com.fittrack.workoutplan.service.WorkoutPlanService;
import com.fittrack.nutrition.entity.*;
import com.fittrack.nutrition.repository.FoodRepository;
import com.fittrack.nutrition.dto.NutritionConvenienceDtos.*;
import com.fittrack.nutrition.service.NutritionConvenienceService;
import com.fittrack.nutrition.planning.*;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.web.server.ResponseStatusException;
import java.time.LocalDate;
import java.util.*;
import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest(classes=FittrackBackendApplication.class) @ActiveProfiles("test")
class TemplateShareIntegrationTest {
 @Autowired TemplateShareService service;
 @Autowired TemplateShareRepository shares;
 @Autowired UserRepository users;
 @Autowired ExerciseRepository exercises;
 @Autowired FoodRepository foods;
 @Autowired WorkoutPlanService plans;
 @Autowired NutritionConvenienceService nutrition;
 @Autowired MealPlanningService planning;
 private User user(String role){return users.save(User.builder().email(UUID.randomUUID()+"@example.com").password("encoded").fullName("Test sharing").role(role).active(true).fitnessEnabled(true).healthEnabled(true).build());}
 private String plan(User owner,Exercise exercise,String name){var e=new CreateWorkoutPlanExerciseRequest();e.setExerciseId(exercise.getId());e.setExerciseOrder(1);e.setTargetSets(3);e.setTargetReps(10);e.setTargetWeight(20.0);e.setTargetRir(2);e.setRestSeconds(90);var day=new CreateWorkoutPlanDayRequest();day.setName("Ngày đẩy");day.setDayOrder(1);day.setExercises(List.of(e));var request=new CreateWorkoutPlanRequest();request.setName(name);request.setDescription("Mẫu chủ động chia sẻ");request.setDays(List.of(day));return plans.createPlan(owner,request).getId();}
 private TemplateShareService.Create input(String kind,String id,User recipient){return new TemplateShareService.Create(kind,id,recipient.getEmail(),UUID.randomUUID().toString(),7);}
 @Test void snapshotIsPrivateIndependentAndAcceptIsIdempotent(){
  var owner=user("USER");var recipient=user("USER");var admin=user("ADMIN");
  var ex=exercises.save(Exercise.builder().name("Press shared").muscleGroup("Chest").active(true).approvalStatus("APPROVED").build());
  var id=plan(owner,ex,"G".repeat(240));var request=input("WORKOUT_PLAN",id,recipient);
  var share=service.create(owner,request);assertEquals(180,share.title().length());
  assertEquals(share.id(),service.create(owner,request).id());
  assertThrows(ResponseStatusException.class,()->service.create(owner,new TemplateShareService.Create("WORKOUT_PLAN",id,recipient.getEmail(),request.operationId(),8)));
  assertThrows(ResponseStatusException.class,()->service.preview(admin,share.id()));
  assertThrows(ResponseStatusException.class,()->service.accept(owner,share.id(),null));
  assertThrows(ResponseStatusException.class,()->service.revoke(recipient,share.id(),share.version()));
  var preview=service.preview(recipient,share.id());assertTrue(preview.unavailableItems().isEmpty());assertEquals(ex.getName(),preview.itemNames().get(ex.getId()));
  var copy=service.accept(recipient,share.id(),null);assertNotEquals(id,copy.id());assertEquals(copy,service.accept(recipient,share.id(),null));
  assertEquals(1,plans.getMyPlans(recipient).size());assertEquals(1,service.list(recipient,true,0,12).totalElements());assertEquals(0,service.list(admin,true,0,12).totalElements());
  plans.deletePlan(owner,id);assertEquals(3,plans.getPlanDetail(recipient,copy.id()).getDays().getFirst().getExercises().getFirst().getTargetSets());
  var current=service.list(owner,false,0,12).content().getFirst();service.revoke(owner,current.id(),current.version());
  assertThrows(ResponseStatusException.class,()->service.preview(recipient,share.id()));assertNotNull(plans.getPlanDetail(recipient,copy.id()));
 }
 @Test void approvalAndPermissionRevocationPreventCopy(){
  var owner=user("USER");var recipient=user("USER");
  var ex=exercises.save(Exercise.builder().name("Shared row").muscleGroup("Back").active(true).approvalStatus("APPROVED").build());
  var share=service.create(owner,input("WORKOUT_PLAN",plan(owner,ex,"Plan"),recipient));
  ex.setActive(false);exercises.save(ex);assertEquals(1,service.preview(recipient,share.id()).unavailableItems().size());assertThrows(ResponseStatusException.class,()->service.accept(recipient,share.id(),null));
  assertTrue(plans.getMyPlans(recipient).isEmpty());ex.setActive(true);exercises.save(ex);
  recipient.setFitnessEnabled(false);users.save(recipient);assertThrows(ResponseStatusException.class,()->service.accept(recipient,share.id(),null));
  recipient.setFitnessEnabled(true);users.save(recipient);owner.setFitnessEnabled(false);users.save(owner);assertThrows(ResponseStatusException.class,()->service.accept(recipient,share.id(),null));
 }
 @Test void mealCopiesArePlansNotDiaryAndNotesStayPrivate(){
  var owner=user("USER");var recipient=user("USER");
  var food=foods.save(Food.builder().name("Shared rice").unit("bát").calories(100.0).protein(2.0).carbs(20.0).fat(1.0).active(true).approvalStatus("APPROVED").build());
  var collection=nutrition.create(owner,new CollectionRequest("Bữa trưa",null,NutritionCollectionType.SAVED_MEAL,1.0,List.of(new CollectionItemRequest(food.getId(),1.0,"SERVING"))));
  var share=service.create(owner,input("MEAL_COLLECTION",collection.id(),recipient));var copy=service.accept(recipient,share.id(),null);assertNotEquals(collection.id(),copy.id());
  var monday=LocalDate.of(2026,10,26);var next=monday.plusWeeks(1);
  planning.create(owner,new PlanningDtos.MealRequest(null,monday,"LUNCH","Cơm dự kiến","PRIVATE NOTE",null,null,List.of(new PlanningDtos.ItemRequest(food.getId(),1.0,"SERVING"))));
  var week=service.create(owner,input("MEAL_WEEK",monday.toString(),recipient));var preview=service.preview(recipient,week.id());assertFalse(preview.template().toString().contains("PRIVATE NOTE"));
  assertThrows(IllegalArgumentException.class,()->service.accept(recipient,week.id(),null));
  var accepted=service.accept(recipient,week.id(),new TemplateShareService.Accept(next));assertEquals(1,accepted.count());assertEquals(accepted,service.accept(recipient,week.id(),new TemplateShareService.Accept(next)));
  var result=planning.list(recipient,next,next.plusDays(6),0,30);assertEquals(1,result.totalElements());assertNull(result.content().getFirst().loggedMealId());
  assertThrows(ResponseStatusException.class,()->service.accept(recipient,week.id(),new TemplateShareService.Accept(next.plusWeeks(1))));
 }
 @Test void expiryLockedRecipientsAndStaleRevokesAreRejected(){
  var owner=user("USER");var recipient=user("USER");var ex=exercises.save(Exercise.builder().name("Press expiry").muscleGroup("Chest").build());var id=plan(owner,ex,"Expiry");
  recipient.setActive(false);users.save(recipient);assertThrows(IllegalArgumentException.class,()->service.create(owner,input("WORKOUT_PLAN",id,recipient)));
  recipient.setActive(true);users.save(recipient);var share=service.create(owner,input("WORKOUT_PLAN",id,recipient));
  assertThrows(ResponseStatusException.class,()->service.revoke(owner,share.id(),share.version()+1));
  var entity=shares.findById(share.id()).orElseThrow();entity.setExpiresAt(java.time.LocalDateTime.now(java.time.ZoneId.of("Asia/Ho_Chi_Minh")).minusSeconds(1));shares.saveAndFlush(entity);
  assertThrows(ResponseStatusException.class,()->service.preview(recipient,share.id()));assertThrows(ResponseStatusException.class,()->service.accept(recipient,share.id(),null));assertTrue(plans.getMyPlans(recipient).isEmpty());
 }
 @Test void simultaneousCreateAndAcceptProduceOneGrantAndOneCopy() throws Exception {
  var owner=user("USER");var recipient=user("USER");var ex=exercises.save(Exercise.builder().name("Press concurrent").muscleGroup("Chest").build());var request=input("WORKOUT_PLAN",plan(owner,ex,"Concurrent"),recipient);
  try(var pool=java.util.concurrent.Executors.newFixedThreadPool(2)){
   var gate=new java.util.concurrent.CountDownLatch(1);
   var a=pool.submit(()->{gate.await();return service.create(owner,request);});var b=pool.submit(()->{gate.await();return service.create(owner,request);});gate.countDown();var share=a.get(20,java.util.concurrent.TimeUnit.SECONDS);assertEquals(share.id(),b.get(20,java.util.concurrent.TimeUnit.SECONDS).id());
   var copyGate=new java.util.concurrent.CountDownLatch(1);var ca=pool.submit(()->{copyGate.await();return service.accept(recipient,share.id(),null);});var cb=pool.submit(()->{copyGate.await();return service.accept(recipient,share.id(),null);});copyGate.countDown();assertEquals(ca.get(20,java.util.concurrent.TimeUnit.SECONDS),cb.get(20,java.util.concurrent.TimeUnit.SECONDS));assertEquals(1,plans.getMyPlans(recipient).size());
  }
 }
}
