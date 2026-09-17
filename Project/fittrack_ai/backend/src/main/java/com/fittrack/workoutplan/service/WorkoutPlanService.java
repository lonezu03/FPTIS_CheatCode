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
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;
import org.springframework.data.domain.PageRequest;
import com.fittrack.common.dto.PageResponse;

@Service
@RequiredArgsConstructor
@Transactional
public class WorkoutPlanService {

    private final WorkoutPlanRepository workoutPlanRepository;
    private final ExerciseRepository exerciseRepository;
    private final WorkoutSessionRepository workoutSessionRepository;
    private final WorkoutPlanMapper workoutPlanMapper;
    private final WorkoutMapper workoutMapper;

    public WorkoutPlanResponse createPlan(User user, CreateWorkoutPlanRequest request) {
        validatePlanRequest(request);
        WorkoutPlan plan = WorkoutPlan.builder()
                .user(user)
                .name(request.getName().trim())
                .description(trim(request.getDescription()))
                .build();
        replaceDays(plan, request.getDays());

        WorkoutPlan saved = workoutPlanRepository.save(plan);

        return workoutPlanMapper.toResponse(saved);
    }

    public WorkoutPlanResponse updatePlan(User user, String planId, CreateWorkoutPlanRequest request) {
        validatePlanRequest(request);
        WorkoutPlan plan = workoutPlanRepository.findByIdAndUser(planId, user)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy giáo án"));
        plan.setName(request.getName().trim());
        plan.setDescription(trim(request.getDescription()));
        plan.getDays().clear();
        replaceDays(plan, request.getDays());
        return workoutPlanMapper.toResponse(workoutPlanRepository.save(plan));
    }

    @Transactional(readOnly = true)
    public List<WorkoutPlanResponse> getMyPlans(User user) {
        return workoutPlanMapper.toResponseList(
                workoutPlanRepository.findByUserOrderByCreatedAtDesc(user)
        );
    }

    @Transactional(readOnly = true)
    public PageResponse<WorkoutPlanResponse> getMyPlansPage(
            User user,
            int page,
            int size
    ) {
        var result = workoutPlanRepository.findByUserOrderByCreatedAtDesc(
                user,
                PageRequest.of(Math.max(page, 0), Math.min(Math.max(size, 1), 100))
        ).map(workoutPlanMapper::toResponse);
        return PageResponse.from(result);
    }

    @Transactional(readOnly = true)
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
                        .exerciseOrder(planExercise.getExerciseOrder() == null ? 1 : planExercise.getExerciseOrder())
                        .setType(com.fittrack.workout.entity.WorkoutSetType.NORMAL)
                        .weight(planExercise.getTargetWeight())
                        .reps(planExercise.getTargetReps())
                        .rir(planExercise.getTargetRir())
                        .restSeconds(90)
                        .completed(true)
                        .build();

                session.getSets().add(set);
            }
        }

        WorkoutSession saved = workoutSessionRepository.save(session);

        return workoutMapper.toWorkoutSessionResponse(saved);
    }

    private void replaceDays(WorkoutPlan plan, List<CreateWorkoutPlanDayRequest> dayRequests) {
        for (CreateWorkoutPlanDayRequest dayRequest : dayRequests) {
            WorkoutPlanDay day = WorkoutPlanDay.builder()
                    .plan(plan)
                    .name(dayRequest.getName().trim())
                    .dayOrder(dayRequest.getDayOrder())
                    .build();
            for (CreateWorkoutPlanExerciseRequest exerciseRequest : dayRequest.getExercises()) {
                Exercise exercise = exerciseRepository.findById(exerciseRequest.getExerciseId())
                        .filter(value -> Boolean.TRUE.equals(value.getActive()))
                        .filter(value -> "APPROVED".equals(value.getApprovalStatus()))
                        .orElseThrow(() -> new IllegalArgumentException("Bài tập không tồn tại hoặc chưa được duyệt"));
                day.getExercises().add(WorkoutPlanExercise.builder()
                        .day(day)
                        .exercise(exercise)
                        .exerciseOrder(exerciseRequest.getExerciseOrder())
                        .targetSets(exerciseRequest.getTargetSets())
                        .targetReps(exerciseRequest.getTargetReps())
                        .targetWeight(exerciseRequest.getTargetWeight())
                        .targetRir(exerciseRequest.getTargetRir())
                        .build());
            }
            plan.getDays().add(day);
        }
    }

    private void validatePlanRequest(CreateWorkoutPlanRequest request) {
        if (request == null || request.getName() == null || request.getName().isBlank()) {
            throw new IllegalArgumentException("Tên giáo án không được để trống");
        }
        if (request.getDays() == null || request.getDays().isEmpty()) {
            throw new IllegalArgumentException("Giáo án phải có ít nhất một ngày tập");
        }
        for (CreateWorkoutPlanDayRequest day : request.getDays()) {
            if (day.getName() == null || day.getName().isBlank()) {
                throw new IllegalArgumentException("Tên ngày tập không được để trống");
            }
            if (day.getDayOrder() == null || day.getDayOrder() < 1) {
                throw new IllegalArgumentException("Thứ tự ngày tập không hợp lệ");
            }
            if (day.getExercises() == null || day.getExercises().isEmpty()) {
                throw new IllegalArgumentException("Mỗi ngày phải có ít nhất một bài tập");
            }
            for (CreateWorkoutPlanExerciseRequest exercise : day.getExercises()) {
                if (exercise.getExerciseId() == null || exercise.getExerciseId().isBlank()) {
                    throw new IllegalArgumentException("Vui lòng chọn bài tập");
                }
                if (exercise.getTargetSets() == null || exercise.getTargetSets() < 1
                        || exercise.getTargetReps() == null || exercise.getTargetReps() < 1) {
                    throw new IllegalArgumentException("Số hiệp và số lần lặp phải lớn hơn 0");
                }
            }
        }
    }

    private String trim(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }
}

