package com.fittrack.workout.service;

import com.fittrack.user.entity.User;
import com.fittrack.workout.dto.CreateWorkoutSessionRequest;
import com.fittrack.workout.dto.CreateWorkoutSetRequest;
import com.fittrack.workout.dto.WorkoutSessionResponse;
import com.fittrack.workout.dto.UpdateWorkoutSessionRequest;
import com.fittrack.workout.entity.Exercise;
import com.fittrack.workout.entity.WorkoutSession;
import com.fittrack.workout.entity.WorkoutSet;
import com.fittrack.workout.mapper.WorkoutMapper;
import com.fittrack.workout.repository.ExerciseRepository;
import com.fittrack.workout.repository.WorkoutSessionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import org.springframework.data.domain.PageRequest;
import com.fittrack.common.dto.PageResponse;

@Service
@RequiredArgsConstructor
public class WorkoutService {

    private final WorkoutSessionRepository workoutSessionRepository;
    private final ExerciseRepository exerciseRepository;
    private final WorkoutMapper workoutMapper;

    @Transactional
    public WorkoutSessionResponse createSession(User user, CreateWorkoutSessionRequest request) {
        WorkoutSession session = WorkoutSession.builder()
                .user(user)
                .sessionDate(request.getSessionDate())
                .note(request.getNote())
                .durationMinutes(request.getDurationMinutes())
                .build();

        if (request.getSets() != null) {
            for (CreateWorkoutSetRequest setRequest : request.getSets()) {
                Exercise exercise = exerciseRepository.findById(setRequest.getExerciseId())
                        .orElseThrow(() -> new IllegalArgumentException("Exercise not found"));

                WorkoutSet set = WorkoutSet.builder()
                        .session(session)
                        .exercise(exercise)
                        .setNumber(setRequest.getSetNumber())
                        .weight(setRequest.getWeight())
                        .reps(setRequest.getReps())
                        .rir(setRequest.getRir())
                        .build();

                session.getSets().add(set);
            }
        }

        WorkoutSession savedSession = workoutSessionRepository.save(session);

        return workoutMapper.toWorkoutSessionResponse(savedSession);
    }

    @Transactional(readOnly = true)
    public List<WorkoutSessionResponse> getMySessions(User user) {
        List<WorkoutSession> sessions = workoutSessionRepository.findByUserOrderBySessionDateDesc(user);

        return workoutMapper.toWorkoutSessionResponseList(sessions);
    }

    @Transactional(readOnly = true)
    public PageResponse<WorkoutSessionResponse> getMySessionsPage(
            User user,
            int page,
            int size
    ) {
        var result = workoutSessionRepository
                .findByUserOrderBySessionDateDescCreatedAtDesc(
                        user,
                        PageRequest.of(Math.max(page, 0), Math.min(Math.max(size, 1), 100))
                )
                .map(workoutMapper::toWorkoutSessionResponse);
        return PageResponse.from(result);
    }

    @Transactional
    public WorkoutSessionResponse updateSession(
            User user,
            String sessionId,
            UpdateWorkoutSessionRequest request
    ) {
        WorkoutSession session = workoutSessionRepository.findByIdAndUser(sessionId, user)
                .orElseThrow(() -> new IllegalArgumentException("Workout session not found"));

        session.setSessionDate(request.getSessionDate());
        session.setNote(request.getNote());
        session.setDurationMinutes(request.getDurationMinutes());

        if (!session.getSets().isEmpty()) {
            WorkoutSet firstSet = session.getSets().get(0);
            firstSet.setWeight(request.getWeight());
            firstSet.setReps(request.getReps());
            firstSet.setRir(request.getRir());
        }

        WorkoutSession saved = workoutSessionRepository.save(session);

        return workoutMapper.toWorkoutSessionResponse(saved);
    }

    @Transactional
    public void deleteSession(User user, String sessionId) {
        WorkoutSession session = workoutSessionRepository.findByIdAndUser(sessionId, user)
                .orElseThrow(() -> new IllegalArgumentException("Workout session not found"));

        workoutSessionRepository.delete(session);
    }
}
