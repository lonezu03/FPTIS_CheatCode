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
    }
}
