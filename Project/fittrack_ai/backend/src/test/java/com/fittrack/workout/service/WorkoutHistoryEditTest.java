package com.fittrack.workout.service;

import com.fittrack.user.entity.User;
import com.fittrack.workout.dto.*;
import com.fittrack.workout.entity.*;
import com.fittrack.workout.mapper.WorkoutMapper;
import com.fittrack.workout.repository.*;
import org.junit.jupiter.api.Test;
import java.time.LocalDate;
import java.util.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class WorkoutHistoryEditTest {
    @Test void createRejectsPendingAndInactiveExercises() {
        var sessions = mock(WorkoutSessionRepository.class);
        var exercises = mock(ExerciseRepository.class);
        var intelligence = mock(WorkoutIntelligenceService.class);
        var service = new WorkoutService(sessions, exercises, mock(WorkoutMapper.class), intelligence);
        var exercise = Exercise.builder().id("pending").active(true).approvalStatus("PENDING").build();
        when(exercises.findById("pending")).thenReturn(Optional.of(exercise));
        var set = new CreateWorkoutSetRequest(); set.setExerciseId("pending");
        var request = new CreateWorkoutSessionRequest(); request.setSets(List.of(set));
        var owner = User.builder().id("owner").build();
        assertThrows(IllegalArgumentException.class, () -> service.createSession(owner, request));
        exercise.setApprovalStatus("APPROVED"); exercise.setActive(false);
        assertThrows(IllegalArgumentException.class, () -> service.createSession(owner, request));
        verify(sessions, never()).save(any()); verifyNoInteractions(intelligence);
    }
    @Test void replacesEverySetAndRejectsForeignOwnerBeforeMutation() {
        var sessions = mock(WorkoutSessionRepository.class);
        var exercises = mock(ExerciseRepository.class);
        var mapper = mock(WorkoutMapper.class);
        var service = new WorkoutService(sessions, exercises, mapper, mock(WorkoutIntelligenceService.class));
        var owner = User.builder().id("owner").build();
        var other = User.builder().id("other").build();
        var session = WorkoutSession.builder().user(owner).build();
        session.getSets().add(WorkoutSet.builder().exercise(Exercise.builder().id("a").build()).weight(99.0).build());
        when(sessions.findByIdAndUser("session", owner)).thenReturn(Optional.of(session));
        when(sessions.findByIdAndUser("session", other)).thenReturn(Optional.empty());
        when(exercises.findById("a")).thenReturn(Optional.of(Exercise.builder().id("a").active(false).approvalStatus("PENDING").build()));
        when(exercises.findById("b")).thenReturn(Optional.of(Exercise.builder().id("b").active(true).approvalStatus("APPROVED").build()));
        var request = new CreateWorkoutSessionRequest();
        request.setSessionDate(LocalDate.of(2026, 10, 25)); request.setDurationMinutes(45); request.setNote("Edited");
        var a = new CreateWorkoutSetRequest(); a.setExerciseId("a"); a.setSetNumber(1); a.setExerciseOrder(1); a.setWeight(20.0); a.setReps(8); a.setRir(2);
        var b = new CreateWorkoutSetRequest(); b.setExerciseId("b"); b.setSetNumber(1); b.setExerciseOrder(2); b.setWeight(30.0); b.setReps(10); b.setRir(1);
        a.setRestSeconds(60); b.setRestSeconds(180);
        request.setSets(List.of(a, b));
        assertThrows(IllegalArgumentException.class, () -> service.replaceSession(other, "session", request));
        assertEquals(99.0, session.getSets().getFirst().getWeight());
        service.replaceSession(owner, "session", request);
        assertEquals(2, session.getSets().size());
        assertEquals("b", session.getSets().get(1).getExercise().getId());
        assertEquals(30.0, session.getSets().get(1).getWeight());
        assertEquals(60, session.getSets().get(0).getRestSeconds());
        assertEquals(180, session.getSets().get(1).getRestSeconds());
        assertEquals(45, session.getDurationMinutes());
    }

    @Test void rejectsUnapprovedNewExerciseBeforeChangingHistoricalAggregate() {
        var sessions = mock(WorkoutSessionRepository.class);
        var exercises = mock(ExerciseRepository.class);
        var service = new WorkoutService(sessions, exercises, mock(WorkoutMapper.class), mock(WorkoutIntelligenceService.class));
        var owner = User.builder().id("owner").build();
        var oldExercise = Exercise.builder().id("old").active(false).approvalStatus("APPROVED").build();
        var session = WorkoutSession.builder().user(owner).note("Keep note").build();
        session.getSets().add(WorkoutSet.builder().exercise(oldExercise).weight(10.0).build());
        when(sessions.findByIdAndUser("session", owner)).thenReturn(Optional.of(session));
        var unapproved = Exercise.builder().id("new").active(true).approvalStatus("PENDING").build();
        when(exercises.findById("new")).thenReturn(Optional.of(unapproved));
        var set = new CreateWorkoutSetRequest(); set.setExerciseId("new");
        var request = new CreateWorkoutSessionRequest(); request.setSets(List.of(set)); request.setNote("Overwrite");
        assertThrows(IllegalArgumentException.class, () -> service.replaceSession(owner, "session", request));
        assertEquals("Keep note", session.getNote()); assertEquals("old", session.getSets().getFirst().getExercise().getId());
        unapproved.setApprovalStatus("APPROVED"); unapproved.setActive(false);
        assertThrows(IllegalArgumentException.class, () -> service.replaceSession(owner, "session", request));
        verify(sessions, never()).save(any());
    }
}
