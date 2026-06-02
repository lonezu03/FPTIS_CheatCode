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

import java.util.List;

@Service
@RequiredArgsConstructor
public class WorkoutService {

    private final WorkoutSessionRepository workoutSessionRepository;
    private final ExerciseRepository exerciseRepository;
    private final WorkoutMapper workoutMapper;

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

    public List<WorkoutSessionResponse> getMySessions(User user) {
        List<WorkoutSession> sessions = workoutSessionRepository.findByUserOrderBySessionDateDesc(user);

        return workoutMapper.toWorkoutSessionResponseList(sessions);
    }

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

    public void deleteSession(User user, String sessionId) {
        WorkoutSession session = workoutSessionRepository.findByIdAndUser(sessionId, user)
                .orElseThrow(() -> new IllegalArgumentException("Workout session not found"));

        workoutSessionRepository.delete(session);
    }
}