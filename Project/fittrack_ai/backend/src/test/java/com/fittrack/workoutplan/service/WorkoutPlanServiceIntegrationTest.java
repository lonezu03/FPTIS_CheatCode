package com.fittrack.workoutplan.service;

import com.fittrack.FittrackBackendApplication;
import com.fittrack.user.entity.User;
import com.fittrack.user.repository.UserRepository;
import com.fittrack.workout.entity.Exercise;
import com.fittrack.workout.repository.ExerciseRepository;
import com.fittrack.workoutplan.dto.CreateWorkoutPlanDayRequest;
import com.fittrack.workoutplan.dto.CreateWorkoutPlanExerciseRequest;
import com.fittrack.workoutplan.dto.CreateWorkoutPlanRequest;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertEquals;

@SpringBootTest(classes = FittrackBackendApplication.class)
@ActiveProfiles("test")
class WorkoutPlanServiceIntegrationTest {

    @Autowired
    private WorkoutPlanService workoutPlanService;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private ExerciseRepository exerciseRepository;
    @Autowired
    private com.fittrack.workout.service.WorkoutService workoutService;

    @Test
    void historyFiltersAndFullReplacementAreOwnerScoped() {
        User owner = userRepository.save(User.builder().email("history-" + UUID.randomUUID() + "@example.com").password("encoded").fullName("History").role("USER").fitnessEnabled(true).build());
        User other = userRepository.save(User.builder().email("other-" + UUID.randomUUID() + "@example.com").password("encoded").fullName("Other").role("USER").fitnessEnabled(true).build());
        Exercise first = exerciseRepository.save(Exercise.builder().name("History Press").muscleGroup("Chest").build());
        Exercise second = exerciseRepository.save(Exercise.builder().name("History Row").muscleGroup("Back").build());
        var request = new com.fittrack.workout.dto.CreateWorkoutSessionRequest();
        request.setSessionDate(java.time.LocalDate.of(2026, 10, 25)); request.setDurationMinutes(30);
        var set = new com.fittrack.workout.dto.CreateWorkoutSetRequest();
        set.setExerciseId(first.getId()); set.setSetNumber(1); set.setExerciseOrder(1); set.setWeight(10.0); set.setReps(8); set.setRir(2); set.setCompleted(true);
        request.setSets(List.of(set));
        var created = workoutService.createSession(owner, request);
        assertEquals(1, workoutService.searchSessions(owner, 0, 12, request.getSessionDate(), request.getSessionDate(), first.getId()).totalElements());
        assertEquals(0, workoutService.searchSessions(other, 0, 12, null, null, first.getId()).totalElements());
        assertEquals(0, workoutService.searchSessions(owner, 0, 12, null, null, second.getId()).totalElements());
        assertEquals(0, workoutService.searchSessions(owner, 0, 12, java.time.LocalDate.of(2026, 10, 1), java.time.LocalDate.of(2026, 10, 24), null).totalElements());
        org.junit.jupiter.api.Assertions.assertThrows(IllegalArgumentException.class, () -> workoutService.replaceSession(other, created.getId(), request));
        var extra = new com.fittrack.workout.dto.CreateWorkoutSetRequest();
        extra.setExerciseId(second.getId()); extra.setSetNumber(1); extra.setExerciseOrder(2); extra.setWeight(25.0); extra.setReps(10); extra.setRir(1); extra.setCompleted(true);
        request.setSets(List.of(set, extra)); request.setDurationMinutes(45);
        workoutService.replaceSession(owner, created.getId(), request);
        var reloaded = workoutService.searchSessions(owner, 0, 12, null, null, second.getId()).content().getFirst();
        assertEquals(2, reloaded.getSets().size()); assertEquals(45, reloaded.getDurationMinutes());
        second.setActive(false); exerciseRepository.save(second);
        extra.setRestSeconds(180); set.setRestSeconds(60);
        var archivedPreserved = workoutService.replaceSession(owner, created.getId(), request);
        assertEquals(60, archivedPreserved.getSets().getFirst().getRestSeconds());
        assertEquals(180, archivedPreserved.getSets().getLast().getRestSeconds());
        Exercise pending = exerciseRepository.save(Exercise.builder().name("Pending Row").muscleGroup("Back").active(true).approvalStatus("PENDING").build());
        extra.setExerciseId(pending.getId());
        org.junit.jupiter.api.Assertions.assertThrows(IllegalArgumentException.class,
                () -> workoutService.replaceSession(owner, created.getId(), request));
        assertEquals(1, workoutService.searchSessions(owner, 0, 12, null, null, second.getId()).totalElements());
    }

    @Test
    void readsNestedPlanDetailsWithOpenInViewDisabled() {
        User user = userRepository.save(User.builder()
                .email("workout-plan-" + UUID.randomUUID() + "@example.com")
                .password("encoded")
                .fullName("Workout plan regression")
                .role("USER")
                .fitnessEnabled(true)
                .build());
        Exercise exercise = exerciseRepository.save(Exercise.builder()
                .name("Dumbbell Shoulder Press")
                .muscleGroup("Vai")
                .equipment("Tạ đơn")
                .description("Đẩy tạ qua đầu và kiểm soát nhịp hạ tạ.")
                .build());

        CreateWorkoutPlanExerciseRequest planExercise = new CreateWorkoutPlanExerciseRequest();
        planExercise.setExerciseId(exercise.getId());
        planExercise.setExerciseOrder(1);
        planExercise.setTargetSets(3);
        planExercise.setTargetReps(10);
        planExercise.setTargetWeight(12.0);
        planExercise.setTargetRir(2);
        planExercise.setRestSeconds(120);
        planExercise.setMinReps(8);
        planExercise.setMaxReps(12);
        planExercise.setCoachingNote("Giữ nhịp chậm");

        CreateWorkoutPlanDayRequest day = new CreateWorkoutPlanDayRequest();
        day.setName("Ngày đẩy");
        day.setDayOrder(1);
        day.setExercises(List.of(planExercise));

        CreateWorkoutPlanRequest request = new CreateWorkoutPlanRequest();
        request.setName("Giáo án tăng cơ");
        request.setDescription("Ba buổi mỗi tuần");
        request.setDays(List.of(day));

        String planId = workoutPlanService.createPlan(user, request).getId();

        var plans = assertDoesNotThrow(() -> workoutPlanService.getMyPlans(user));
        var page = assertDoesNotThrow(() -> workoutPlanService.getMyPlansPage(user, 0, 12));
        var detail = assertDoesNotThrow(() -> workoutPlanService.getPlanDetail(user, planId));
        assertEquals(120, detail.getDays().getFirst().getExercises().getFirst().getRestSeconds());
        var generation = new com.fittrack.workoutplan.dto.GenerateSessionFromPlanRequest();
        generation.setDayId(detail.getDays().getFirst().getId());
        var session = workoutPlanService.generateSessionFromPlan(user, planId, generation);
        assertEquals(0, session.getDurationMinutes());
        org.junit.jupiter.api.Assertions.assertNull(session.getId());
        org.junit.jupiter.api.Assertions.assertTrue(session.getSets().stream().noneMatch(value -> Boolean.TRUE.equals(value.getCompleted())));
        assertEquals(120, session.getSets().getFirst().getRestSeconds());

        assertEquals(1, plans.size());
        assertEquals(1, page.content().size());
        assertEquals("Dumbbell Shoulder Press", detail.getDays().getFirst()
                .getExercises().getFirst().getExerciseName());
        assertEquals("Vai", detail.getDays().getFirst()
                .getExercises().getFirst().getMuscleGroup());
        assertEquals("Tạ đơn", detail.getDays().getFirst()
                .getExercises().getFirst().getEquipment());
        assertEquals("Đẩy tạ qua đầu và kiểm soát nhịp hạ tạ.", detail.getDays().getFirst()
                .getExercises().getFirst().getDescription());

        planExercise.setTargetSets(4);
        planExercise.setTargetReps(8);
        day.setName("Ngày vai cập nhật");
        request.setName("Giáo án đã chỉnh sửa");
        request.setDescription("Kiểm tra cập nhật lồng nhau");

        var updated = assertDoesNotThrow(() -> workoutPlanService.updatePlan(user, planId, request));
        var reloaded = assertDoesNotThrow(() -> workoutPlanService.getPlanDetail(user, planId));

        assertEquals("Giáo án đã chỉnh sửa", updated.getName());
        assertEquals("Ngày vai cập nhật", reloaded.getDays().getFirst().getName());
        assertEquals(4, reloaded.getDays().getFirst().getExercises().getFirst().getTargetSets());
        assertEquals(8, reloaded.getDays().getFirst().getExercises().getFirst().getTargetReps());
        request.setVersion(detail.getVersion());
        org.junit.jupiter.api.Assertions.assertThrows(org.springframework.web.server.ResponseStatusException.class,
                () -> workoutPlanService.updatePlan(user, planId, request));
        request.setVersion(null);
        planExercise.setMinReps(15);
        org.junit.jupiter.api.Assertions.assertThrows(IllegalArgumentException.class,
                () -> workoutPlanService.updatePlan(user, planId, request));
    }
}
