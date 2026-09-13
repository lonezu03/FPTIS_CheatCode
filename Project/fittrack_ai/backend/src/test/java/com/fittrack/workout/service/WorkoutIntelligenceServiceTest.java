package com.fittrack.workout.service;

import com.fittrack.user.entity.User;
import com.fittrack.workout.entity.Exercise;
import com.fittrack.workout.entity.ExercisePreference;
import com.fittrack.workout.entity.ExercisePreferenceLevel;
import com.fittrack.workout.entity.WorkoutSession;
import com.fittrack.workout.entity.WorkoutSet;
import com.fittrack.workout.entity.WorkoutSetType;
import com.fittrack.workout.mapper.WorkoutMapper;
import com.fittrack.workout.repository.ExercisePreferenceRepository;
import com.fittrack.workout.repository.ExerciseRepository;
import com.fittrack.workout.repository.WorkoutSessionRepository;
import com.fittrack.workout.repository.WorkoutSetRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.springframework.data.domain.Pageable;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;

class WorkoutIntelligenceServiceTest {

    @Mock
    private ExerciseRepository exerciseRepository;
    @Mock
    private ExercisePreferenceRepository preferenceRepository;
    @Mock
    private WorkoutSessionRepository sessionRepository;
    @Mock
    private WorkoutSetRepository setRepository;

    private final WorkoutMapper workoutMapper = new WorkoutMapper();
    private WorkoutIntelligenceService service;
    private User user;
    private Exercise press;

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
        service = new WorkoutIntelligenceService(
                exerciseRepository,
                preferenceRepository,
                sessionRepository,
                setRepository,
                workoutMapper
        );
        user = User.builder().id("user-1").email("user@example.test").build();
        press = Exercise.builder()
                .id("press")
                .name("Incline Dumbbell Press")
                .muscleGroup("Chest")
                .equipment("Dumbbell")
                .active(true)
                .approvalStatus("APPROVED")
                .build();
    }

    @Test
    void increasesWeightOnlyAfterAllTargetSetsReachTopRangeWithEnoughRir() {
        WorkoutSession previous = session("previous", LocalDate.of(2026, 9, 10));
        previous.setSets(List.of(
                set(previous, press, 1, WorkoutSetType.NORMAL, 20, 10, 2),
                set(previous, press, 2, WorkoutSetType.NORMAL, 20, 10, 3),
                set(previous, press, 3, WorkoutSetType.NORMAL, 20, 10, 2)
        ));
        when(exerciseRepository.findById("press")).thenReturn(Optional.of(press));
        when(sessionRepository.findLatestContainingExercise(
                eq(user), eq("press"), any(Pageable.class)
        )).thenReturn(List.of(previous));
        when(setRepository.findCompletedByUserAndExercise(user, "press"))
                .thenReturn(previous.getSets());

        var result = service.getIntelligence(user, "press", 3, 8, 10, 2);

        assertEquals("INCREASE_WEIGHT", result.progression().action());
        assertEquals(22.0, result.progression().suggestedWeight());
        assertEquals(8, result.progression().suggestedMinReps());
        assertTrue(result.progression().hasEnoughData());
        assertTrue(result.personalBests().stream()
                .anyMatch(record -> "ESTIMATED_1RM".equals(record.type())));
    }

    @Test
    void weeklyVolumeExcludesWarmupsAndComparesPreviousWeek() {
        LocalDate monday = LocalDate.of(2026, 9, 7);
        WorkoutSession current = session("current", monday.plusDays(1));
        WorkoutSession previous = session("previous", monday.minusDays(2));
        List<WorkoutSet> currentSets = List.of(
                set(current, press, 1, WorkoutSetType.WARMUP, 10, 10, 4),
                set(current, press, 2, WorkoutSetType.NORMAL, 20, 10, 2),
                set(current, press, 3, WorkoutSetType.NORMAL, 20, 10, 2)
        );
        List<WorkoutSet> previousSets = List.of(
                set(previous, press, 1, WorkoutSetType.NORMAL, 18, 10, 2)
        );
        when(setRepository.findCompletedByUserAndDateBetween(
                user, monday, monday.plusDays(6)
        )).thenReturn(currentSets);
        when(setRepository.findCompletedByUserAndDateBetween(
                user, monday.minusWeeks(1), monday.minusDays(1)
        )).thenReturn(previousSets);

        var result = service.getWeeklyVolume(user, monday);

        assertEquals(2, result.totalWorkingSets());
        assertEquals(400.0, result.totalVolume());
        assertEquals(1, result.muscleGroups().size());
        assertEquals(1, result.muscleGroups().get(0).changeSets());
    }

    @Test
    void alternativesExcludeBlockedExercisesAndPreferFavorites() {
        Exercise favorite = exercise("favorite", "Chest Supported Press", "Chest", "Machine");
        Exercise normal = exercise("normal", "Barbell Bench Press", "Chest", "Barbell");
        Exercise excluded = exercise("excluded", "Cable Press", "Chest", "Cable");
        Exercise otherMuscle = exercise("row", "Cable Row", "Back", "Cable");
        when(exerciseRepository.findById("press")).thenReturn(Optional.of(press));
        when(exerciseRepository.findByActiveTrueOrderByNameAsc()).thenReturn(
                List.of(normal, excluded, favorite, otherMuscle)
        );
        when(preferenceRepository.findByUser(user)).thenReturn(List.of(
                preference(favorite, ExercisePreferenceLevel.FAVORITE),
                preference(excluded, ExercisePreferenceLevel.EXCLUDED)
        ));

        var result = service.getAlternatives(user, "press");

        assertEquals(List.of("favorite", "normal"), result.stream()
                .map(value -> value.exercise().getId()).toList());
        assertFalse(result.stream()
                .anyMatch(value -> "excluded".equals(value.exercise().getId())));
    }

    @Test
    void detectsNewRecordsAgainstHistoryAndIgnoresWarmupSets() {
        WorkoutSession previous = session("previous", LocalDate.of(2026, 9, 10));
        List<WorkoutSet> history = List.of(
                set(previous, press, 1, WorkoutSetType.NORMAL, 20, 10, 2)
        );
        WorkoutSession candidate = session("candidate", LocalDate.of(2026, 9, 13));
        candidate.setSets(List.of(
                set(candidate, press, 1, WorkoutSetType.WARMUP, 100, 1, 5),
                set(candidate, press, 2, WorkoutSetType.NORMAL, 22, 10, 2)
        ));
        when(setRepository.findCompletedByUserAndExercise(user, "press"))
                .thenReturn(history);

        var records = service.detectNewRecords(user, candidate);

        assertTrue(records.stream().anyMatch(record ->
                "HEAVIEST_WEIGHT".equals(record.type())
                        && record.newValue().equals(22.0)));
        assertTrue(records.stream().anyMatch(record ->
                "ESTIMATED_1RM".equals(record.type())));
        assertFalse(records.stream().anyMatch(record ->
                record.newValue().equals(100.0)));
    }

    private WorkoutSession session(String id, LocalDate date) {
        return WorkoutSession.builder()
                .id(id)
                .user(user)
                .sessionDate(date)
                .sets(new java.util.ArrayList<>())
                .build();
    }

    private WorkoutSet set(
            WorkoutSession session,
            Exercise exercise,
            int number,
            WorkoutSetType type,
            double weight,
            int reps,
            int rir
    ) {
        return WorkoutSet.builder()
                .id(session.getId() + "-" + number)
                .session(session)
                .exercise(exercise)
                .setNumber(number)
                .exerciseOrder(1)
                .setType(type)
                .weight(weight)
                .reps(reps)
                .rir(rir)
                .completed(true)
                .build();
    }

    private Exercise exercise(
            String id,
            String name,
            String muscle,
            String equipment
    ) {
        return Exercise.builder()
                .id(id)
                .name(name)
                .muscleGroup(muscle)
                .equipment(equipment)
                .active(true)
                .approvalStatus("APPROVED")
                .build();
    }

    private ExercisePreference preference(
            Exercise exercise,
            ExercisePreferenceLevel level
    ) {
        return ExercisePreference.builder()
                .user(user)
                .exercise(exercise)
                .preference(level)
                .build();
    }
}
