package com.fittrack.workout.service;
import com.fittrack.user.entity.User;
import com.fittrack.workout.entity.*;
import com.fittrack.workout.dto.*;
import com.fittrack.workout.mapper.WorkoutMapper;
import com.fittrack.workout.repository.*;
import org.junit.jupiter.api.Test;
import java.time.LocalDate;
import java.util.*;
import static org.mockito.Mockito.*;
import static org.junit.jupiter.api.Assertions.*;
class WorkoutSubstitutionTest {
 @Test void savesActualAndOriginalSeparatelyWithoutRewritingCompletedOriginal(){
  var sessions=mock(WorkoutSessionRepository.class);var exercises=mock(ExerciseRepository.class);var intelligence=mock(WorkoutIntelligenceService.class);
  var service=new WorkoutService(sessions,exercises,new WorkoutMapper(),intelligence);var user=User.builder().id("u").build();
  var original=Exercise.builder().id("old").name("Máy đẩy").muscleGroup("Chest").active(true).approvalStatus("APPROVED").build();
  var actual=Exercise.builder().id("new").name("Tạ đơn").muscleGroup("Chest").active(true).approvalStatus("APPROVED").build();
  when(exercises.findById("old")).thenReturn(Optional.of(original));when(exercises.findById("new")).thenReturn(Optional.of(actual));when(intelligence.isAllowedAlternative(user,original,actual)).thenReturn(true);when(sessions.save(any())).thenAnswer(i->i.getArgument(0));when(intelligence.detectNewRecords(any(),any())).thenReturn(List.of());
  var oldSet=set("old",60);var newSet=set("new",20);newSet.setOriginalExerciseId("old");newSet.setExerciseOrder(2);
  var request=new CreateWorkoutSessionRequest();request.setSessionDate(LocalDate.now());request.setSets(List.of(oldSet,newSet));
  var result=service.createSession(user,request);assertEquals("old",result.getSets().getFirst().getExerciseId());assertNull(result.getSets().getFirst().getOriginalExerciseId());assertEquals(60,result.getSets().getFirst().getWeight());assertEquals("new",result.getSets().getLast().getExerciseId());assertEquals("old",result.getSets().getLast().getOriginalExerciseId());
  newSet.setReplacementKind("MANUAL");when(intelligence.isAllowedAlternative(user,original,actual)).thenReturn(false);var manual=service.createSession(user,request);assertEquals("old",manual.getSets().getLast().getOriginalExerciseId());assertEquals("MANUAL",manual.getSets().getLast().getReplacementKind());
  newSet.setReplacementKind("ALTERNATIVE");assertThrows(IllegalArgumentException.class,()->service.createSession(user,request));
 }
 private CreateWorkoutSetRequest set(String exercise,double weight){var s=new CreateWorkoutSetRequest();s.setExerciseId(exercise);s.setSetNumber(1);s.setExerciseOrder(1);s.setWeight(weight);s.setReps(10);s.setRir(2);s.setCompleted(true);return s;}
}
