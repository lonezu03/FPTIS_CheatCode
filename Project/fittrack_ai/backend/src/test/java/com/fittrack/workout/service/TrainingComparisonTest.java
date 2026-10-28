package com.fittrack.workout.service;
import com.fittrack.workout.entity.*;
import org.junit.jupiter.api.Test;
import java.time.*;
import java.util.*;
import static org.junit.jupiter.api.Assertions.*;
class TrainingComparisonTest {
 @Test void onlyCompletedWorkingSetsAndValidRepRangeEstimate(){var e=Exercise.builder().id("e").name("Máy kéo").build();var session=WorkoutSession.builder().id("s").sessionDate(LocalDate.of(2026,10,20)).build();var actual=WorkoutSet.builder().session(session).exercise(e).setType(WorkoutSetType.NORMAL).weight(60.0).reps(10).completed(true).build();var warm=WorkoutSet.builder().session(session).exercise(e).setType(WorkoutSetType.WARMUP).weight(100.0).reps(2).completed(true).build();var high=WorkoutSet.builder().session(session).exercise(e).setType(WorkoutSetType.NORMAL).weight(20.0).reps(40).completed(true).build();var result=TrainingComparisonService.summarize(List.of(actual,warm,high),session.getSessionDate(),session.getSessionDate(),null,null);assertEquals(2,result.workingSets());assertEquals(1400,result.volume());assertEquals(80,result.exercises().getFirst().estimated1rm(),0.001);assertNull(result.adherence());}
 @Test void noLinkedDataIsUnknownAdherenceNotZero(){var result=TrainingComparisonService.summarize(List.of(),LocalDate.now(),LocalDate.now(),"plan",0L);assertEquals(0,result.completedSessions());assertNull(result.adherence());assertTrue(result.exercises().isEmpty());}
}
