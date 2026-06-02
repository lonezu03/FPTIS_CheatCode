package com.fittrack.workoutplan.service;

import com.fittrack.user.entity.User;
import com.fittrack.workout.entity.Exercise;
import com.fittrack.workout.entity.WorkoutSession;
import com.fittrack.workout.entity.WorkoutSet;
import com.fittrack.workout.mapper.WorkoutMapper;
import com.fittrack.workout.repository.ExerciseRepository;
import com.fittrack.workout.repository.WorkoutSessionRepository;
import com.fittrack.workout.dto.WorkoutSessionResponse;
import com.fittrack.workoutplan.dto.*;
import com.fittrack.workoutplan.entity.WorkoutPlan;
import com.fittrack.workoutplan.entity.WorkoutPlanDay;
import com.fittrack.workoutplan.entity.WorkoutPlanExercise;
import com.fittrack.workoutplan.mapper.WorkoutPlanMapper;
import com.fittrack.workoutplan.repository.WorkoutPlanRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.List;

@Service
@RequiredArgsConstructor
public class WorkoutPlanService {

    private final WorkoutPlanRepository workoutPlanRepository;
    private final ExerciseRepository exerciseRepository;
    private final WorkoutSessionRepository workoutSessionRepository;
    private final WorkoutPlanMapper workoutPlanMapper;
    private final WorkoutMapper workoutMapper;

    public WorkoutPlanResponse createPlan(User user, CreateWorkoutPlanRequest request) {
        WorkoutPlan plan = WorkoutPlan.builder()
                .user(user)
                .name(request.getName())
                .description(request.getDescription())
                .build();

        if (request.getDays() != null) {
            for (CreateWorkoutPlanDayRequest dayRequest : request.getDays()) {
                WorkoutPlanDay day = WorkoutPlanDay.builder()
                        .plan(plan)
                        .name(dayRequest.getName())
                        .dayOrder(dayRequest.getDayOrder())
                        .build();

                if (dayRequest.getExercises() != null) {
                    for (CreateWorkoutPlanExerciseRequest exerciseRequest : dayRequest.getExercises()) {
                        Exercise exercise = exerciseRepository.findById(exerciseRequest.getExerciseId())
                                .orElseThrow(() -> new IllegalArgumentException("Exercise not found"));

                        WorkoutPlanExercise planExercise = WorkoutPlanExercise.builder()
                                .day(day)
                                .exercise(exercise)
                                .exerciseOrder(exerciseRequest.getExerciseOrder())
                                .targetSets(exerciseRequest.getTargetSets())
                                .targetReps(exerciseRequest.getTargetReps())
                                .targetWeight(exerciseRequest.getTargetWeight())
                                .targetRir(exerciseRequest.getTargetRir())
                                .build();

                        day.getExercises().add(planExercise);
                    }
                }

                plan.getDays().add(day);
            }
        }

        WorkoutPlan saved = workoutPlanRepository.save(plan);

        return workoutPlanMapper.toResponse(saved);
    }

    public List<WorkoutPlanResponse> getMyPlans(User user) {
        return workoutPlanMapper.toResponseList(
                workoutPlanRepository.findByUserOrderByCreatedAtDesc(user)
        );
    }

    public WorkoutPlanResponse getPlanDetail(User user, String planId) {
        WorkoutPlan plan = workoutPlanRepository.findByIdAndUser(planId, user)
                .orElseThrow(() -> new IllegalArgumentException("Workout plan not found"));

        return workoutPlanMapper.toResponse(plan);
    }

    public void deletePlan(User user, String planId) {
        WorkoutPlan plan = workoutPlanRepository.findByIdAndUser(planId, user)
                .orElseThrow(() -> new IllegalArgumentException("Workout plan not found"));

        workoutPlanRepository.delete(plan);
    }

    public WorkoutSessionResponse generateSessionFromPlan(
            User user,
            String planId,
            GenerateSessionFromPlanRequest request
    ) {
        WorkoutPlan plan = workoutPlanRepository.findByIdAndUser(planId, user)
                .orElseThrow(() -> new IllegalArgumentException("Workout plan not found"));

        WorkoutPlanDay selectedDay = plan.getDays()
                .stream()
                .filter(day -> day.getId().equals(request.getDayId()))
                .findFirst()
                .orElseThrow(() -> new IllegalArgumentException("Workout plan day not found"));

        WorkoutSession session = WorkoutSession.builder()
                .user(user)
                .sessionDate(request.getSessionDate() == null ? LocalDate.now() : request.getSessionDate())
                .note(request.getNote() == null ? plan.getName() + " - " + selectedDay.getName() : request.getNote())
                .durationMinutes(60)
                .build();

        for (WorkoutPlanExercise planExercise : selectedDay.getExercises()) {
            int targetSets = planExercise.getTargetSets() == null ? 3 : planExercise.getTargetSets();

            for (int i = 1; i <= targetSets; i++) {
                WorkoutSet set = WorkoutSet.builder()
                        .session(session)
                        .exercise(planExercise.getExercise())
                        .setNumber(i)
                        .weight(planExercise.getTargetWeight())
                        .reps(planExercise.getTargetReps())
                        .rir(planExercise.getTargetRir())
                        .build();

                session.getSets().add(set);
            }
        }

        WorkoutSession saved = workoutSessionRepository.save(session);

        return workoutMapper.toWorkoutSessionResponse(saved);
    }
}

