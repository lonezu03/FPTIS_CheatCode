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
        if (request.getVersion() != null && !request.getVersion().equals(plan.getVersion())) {
            throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.CONFLICT, "Giáo án đã thay đổi, hãy tải lại trước khi lưu");
        }
        plan.setName(request.getName().trim());
        plan.setUpdatedAt(java.time.LocalDateTime.now());
        plan.setDescription(trim(request.getDescription()));
        plan.getDays().clear();
        replaceDays(plan, request.getDays());
        return workoutPlanMapper.toResponse(workoutPlanRepository.saveAndFlush(plan));
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
                .durationMinutes(0)
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
                        .restSeconds(planExercise.getRestSeconds() == null ? 90 : planExercise.getRestSeconds())
                        .completed(false)
                        .build();

                session.getSets().add(set);
            }
        }

        // A prescription is an unsaved draft, never a completed workout/history entry.
        // Keep the legacy response shape for older clients; only explicit session completion persists history.
        return workoutMapper.toWorkoutSessionResponse(session);
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
                        .restSeconds(exerciseRequest.getRestSeconds())
                        .minReps(exerciseRequest.getMinReps())
                        .maxReps(exerciseRequest.getMaxReps())
                        .coachingNote(trim(exerciseRequest.getCoachingNote()))
                        .build());
            }
            plan.getDays().add(day);
        }
    }

    private void validatePlanRequest(CreateWorkoutPlanRequest request) {
        if (request == null || request.getName() == null || request.getName().isBlank()) {
            throw new IllegalArgumentException("Tên giáo án không được để trống");
        }
        if (request.getName().length() > 255 || request.getDescription() != null && request.getDescription().length() > 255) {
            throw new IllegalArgumentException("Tên và mô tả tối đa 255 ký tự");
        }
        if (request.getDays() == null || request.getDays().isEmpty() || request.getDays().size() > 31) {
            throw new IllegalArgumentException("Giáo án phải có ít nhất một ngày tập");
        }
        for (CreateWorkoutPlanDayRequest day : request.getDays()) {
            if (day == null || day.getExercises() == null || day.getExercises().size() > 50) {
                throw new IllegalArgumentException("Giáo án tối đa 31 ngày, mỗi ngày tối đa 50 bài tập");
            }
            if (day.getName() == null || day.getName().isBlank() || day.getName().length() > 255) {
                throw new IllegalArgumentException("Tên ngày tập không được để trống");
            }
            if (day.getDayOrder() == null || day.getDayOrder() < 1) {
                throw new IllegalArgumentException("Thứ tự ngày tập không hợp lệ");
            }
            if (day.getExercises() == null || day.getExercises().isEmpty()) {
                throw new IllegalArgumentException("Mỗi ngày phải có ít nhất một bài tập");
            }
            for (CreateWorkoutPlanExerciseRequest exercise : day.getExercises()) {
                if (exercise == null) throw new IllegalArgumentException("Bài tập không hợp lệ");
                if (exercise.getTargetSets() != null && exercise.getTargetSets() > 20
                        || exercise.getTargetReps() != null && exercise.getTargetReps() > 100
                        || exercise.getTargetWeight() != null && (!Double.isFinite(exercise.getTargetWeight()) || exercise.getTargetWeight() < 0 || exercise.getTargetWeight() > 2000)
                        || exercise.getTargetRir() != null && (exercise.getTargetRir() < 0 || exercise.getTargetRir() > 10)
                        || exercise.getRestSeconds() != null && (exercise.getRestSeconds() < 0 || exercise.getRestSeconds() > 1800)
                        || exercise.getMinReps() != null && (exercise.getMinReps() < 1 || exercise.getMinReps() > 100)
                        || exercise.getMaxReps() != null && (exercise.getMaxReps() < 1 || exercise.getMaxReps() > 100)
                        || exercise.getMinReps() != null && exercise.getMaxReps() != null && exercise.getMinReps() > exercise.getMaxReps()
                        || exercise.getCoachingNote() != null && exercise.getCoachingNote().length() > 1000
                        || exercise.getExerciseOrder() != null && (exercise.getExerciseOrder() < 1 || exercise.getExerciseOrder() > 50)) {
                    throw new IllegalArgumentException("Thông số bài tập ngoài giới hạn cho phép");
                }
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

