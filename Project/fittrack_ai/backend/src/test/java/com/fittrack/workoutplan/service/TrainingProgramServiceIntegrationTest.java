package com.fittrack.workoutplan.service;
import com.fittrack.FittrackBackendApplication;
import com.fittrack.user.entity.User;
import com.fittrack.user.repository.UserRepository;
import com.fittrack.workout.entity.Exercise;
import com.fittrack.workout.repository.ExerciseRepository;
import com.fittrack.workout.repository.WorkoutSessionRepository;
import com.fittrack.workoutplan.dto.*;
import com.fittrack.workoutplan.dto.TrainingProgramDtos.*;
import com.fittrack.workout.dto.*;
import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import java.time.*;
import java.util.*;
import static org.junit.jupiter.api.Assertions.*;
@SpringBootTest(classes=FittrackBackendApplication.class) @ActiveProfiles("test")
class TrainingProgramServiceIntegrationTest {
 @Autowired TrainingProgramService programs;
 @Autowired WorkoutPlanService plans;
 @Autowired UserRepository users;
 @Autowired ExerciseRepository exercises;
 @Autowired WorkoutSessionRepository sessions;
 User user(){return users.save(User.builder().email(UUID.randomUUID()+"@example.com").password("encoded").fullName("Training").role("USER").fitnessEnabled(true).scheduleEnabled(true).build());}
 CreateWorkoutPlanRequest plan(String name,String exercise){
  var e=new CreateWorkoutPlanExerciseRequest();e.setExerciseId(exercise);e.setExerciseOrder(1);e.setTargetSets(3);e.setTargetReps(8);e.setTargetWeight(20.0);e.setTargetRir(2);
  e.setGroupKey("A");e.setGroupType("SUPERSET");e.setGroupRounds(3);e.setBetweenExerciseRestSeconds(15);e.setBetweenRoundRestSeconds(90);
  var d=new CreateWorkoutPlanDayRequest();d.setName("Đẩy");d.setDayOrder(1);d.setExercises(List.of(e));
  var p=new CreateWorkoutPlanRequest();p.setName(name);p.setDays(List.of(d));return p;
 }
 @Test void schedulingPreservesSnapshotAndDoesNotCreateHistoryAndCompletesEachOccurrenceOnce(){
  User u=user(),other=user();Exercise e=exercises.save(Exercise.builder().name("Press").muscleGroup("Chest").build());
  var plan=plans.createPlan(u,plan("Original",e.getId()));
  var before=sessions.findByUserOrderBySessionDateDesc(u).size();
  var occurrences=programs.schedule(u,new AppointmentRequest(plan.getId(),plan.getDays().getFirst().getId(),LocalDateTime.of(2026,11,1,18,0),2,null,null));
  assertEquals(before,sessions.findByUserOrderBySessionDateDesc(u).size());
  var update=plan("Changed",e.getId());update.setVersion(plan.getVersion());plans.updatePlan(u,plan.getId(),update);
  var snapshot=programs.appointment(u,occurrences.getFirst().id());
  assertTrue(snapshot.title().startsWith("Original"));assertEquals("A",snapshot.day().getExercises().getFirst().getGroupKey());
  assertThrows(IllegalArgumentException.class,()->programs.appointment(other,snapshot.id()));
  var set=new CreateWorkoutSetRequest();set.setExerciseId(e.getId());set.setExerciseOrder(1);set.setSetNumber(1);set.setWeight(20.0);set.setReps(8);set.setRir(2);set.setCompleted(true);
  set.setGroupKey("A");set.setGroupType("SUPERSET");set.setGroupRounds(3);set.setBetweenExerciseRestSeconds(15);set.setBetweenRoundRestSeconds(90);
  var actual=new CreateWorkoutSessionRequest();actual.setSessionDate(LocalDate.of(2026,11,1));actual.setDurationMinutes(30);actual.setSets(List.of(set));
  set.setCompleted(false);
  assertThrows(IllegalArgumentException.class,()->programs.complete(u,snapshot.id(),new Completion(actual)));
  set.setCompleted(true);set.setSetType(com.fittrack.workout.entity.WorkoutSetType.WARMUP);
  assertThrows(IllegalArgumentException.class,()->programs.complete(u,snapshot.id(),new Completion(actual)));
  set.setSetType(com.fittrack.workout.entity.WorkoutSetType.NORMAL);
  var first=programs.complete(u,snapshot.id(),new Completion(actual));
  var retry=programs.complete(u,snapshot.id(),new Completion(actual));
  assertEquals(first.getId(),retry.getId());assertEquals(before+1,sessions.findByUserOrderBySessionDateDesc(u).size());
  assertEquals("SUPERSET",retry.getSets().getFirst().getGroupType());
  assertNull(programs.appointment(u,occurrences.get(1).id()).completedSessionId());
  assertEquals("DONE",programs.calendar(u,LocalDateTime.of(2026,11,1,0,0),LocalDateTime.of(2026,11,10,0,0)).getFirst().status());
 }
 @Test void cyclesValidateWeeksOwnershipVersionAndSchedulingPermission(){
  User u=user(),other=user();var weeks=java.util.stream.IntStream.rangeClosed(1,4).mapToObj(n->new Week(n,n==4,3,"Giữ tải đã xác nhận")).toList();
  var c=programs.saveCycle(u,null,new CycleRequest("4 weeks",LocalDate.of(2026,11,1),null,weeks));
  assertEquals(4,c.weeks().size());assertEquals(0,c.completedSessions());
  assertThrows(IllegalArgumentException.class,()->programs.saveCycle(other,c.id(),new CycleRequest("Other",c.startDate(),c.version(),weeks)));
  assertThrows(org.springframework.web.server.ResponseStatusException.class,()->programs.saveCycle(u,c.id(),new CycleRequest("Stale",c.startDate(),99L,weeks)));
  assertThrows(IllegalArgumentException.class,()->programs.saveCycle(u,null,new CycleRequest("Short",c.startDate(),null,weeks.subList(0,3))));
  Exercise exercise=exercises.save(Exercise.builder().name("Cycle press").muscleGroup("Chest").build());
  var longPlan=plan("P".repeat(220),exercise.getId());longPlan.getDays().getFirst().setName("D".repeat(200));
  var saved=plans.createPlan(u,longPlan);
  assertThrows(IllegalArgumentException.class,()->programs.schedule(u,new AppointmentRequest(saved.getId(),saved.getDays().getFirst().getId(),c.startDate().atTime(18,0),5,c.id(),1)));
  assertEquals(0,programs.appointments(u,c.startDate().atStartOfDay(),c.startDate().plusWeeks(6).atStartOfDay()).size());
  var schedule=programs.schedule(u,new AppointmentRequest(saved.getId(),saved.getDays().getFirst().getId(),c.startDate().atTime(18,0),4,c.id(),1));
  assertEquals(255,schedule.getFirst().title().length());
  assertEquals(4,programs.cycles(u,0,12).content().getFirst().plannedSessions());
  assertEquals(0,programs.cycles(u,0,12).content().getFirst().completedSessions());
  u.setScheduleEnabled(false);User locked=u;
  assertThrows(org.springframework.web.server.ResponseStatusException.class,()->programs.appointments(locked,LocalDateTime.now(),LocalDateTime.now().plusDays(1)));
 }
 @Test void groupsRejectInconsistentConfiguration(){
  assertThrows(IllegalArgumentException.class,()->WorkoutGroups.validate(List.of(new WorkoutGroups.Group("A","SUPERSET",3,15,90),new WorkoutGroups.Group("A","CIRCUIT",3,15,90))));
  assertThrows(IllegalArgumentException.class,()->WorkoutGroups.validate(List.of(new WorkoutGroups.Group("A","SUPERSET",0,15,90))));
 }
}
