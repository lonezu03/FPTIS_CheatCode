package com.fittrack.workout.service;

import com.fittrack.user.entity.User;
import com.fittrack.workout.dto.CreateWorkoutSessionRequest;
import com.fittrack.workout.dto.CreateWorkoutSetRequest;
import com.fittrack.workout.dto.WorkoutSessionResponse;
import com.fittrack.workout.dto.PreviousWorkoutPerformanceResponse;
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
    private final WorkoutIntelligenceService workoutIntelligenceService;

    @Transactional
    public WorkoutSessionResponse createSession(User user, CreateWorkoutSessionRequest request) {
        validateGroups(request);
        WorkoutSession session = WorkoutSession.builder()
                .user(user)
                .sessionDate(request.getSessionDate())
                .note(request.getNote())
                .durationMinutes(request.getDurationMinutes())
                .build();

        if (request.getSets() != null) {
            for (CreateWorkoutSetRequest setRequest : request.getSets()) {
                Exercise exercise = exerciseRepository.findById(setRequest.getExerciseId())
                        .filter(value -> Boolean.TRUE.equals(value.getActive()) && "APPROVED".equals(value.getApprovalStatus()))
                        .orElseThrow(() -> new IllegalArgumentException("Bài tập phải đang hoạt động và đã được duyệt"));

                WorkoutSet set = WorkoutSet.builder()
                        .originalExerciseId(validateOriginal(user,setRequest,exercise))
                        .replacementKind(setRequest.getReplacementKind())
                        .session(session)
                        .exercise(exercise)
                        .setNumber(setRequest.getSetNumber())
                        .groupKey(setRequest.getGroupKey())
                        .groupType(setRequest.getGroupType())
                        .groupRounds(setRequest.getGroupRounds())
                        .betweenExerciseRestSeconds(setRequest.getBetweenExerciseRestSeconds())
                        .betweenRoundRestSeconds(setRequest.getBetweenRoundRestSeconds())
                        .exerciseOrder(setRequest.getExerciseOrder() == null ? 1 : setRequest.getExerciseOrder())
                        .setType(setRequest.getSetType() == null
                                ? com.fittrack.workout.entity.WorkoutSetType.NORMAL
                                : setRequest.getSetType())
                        .weight(setRequest.getWeight())
                        .reps(setRequest.getReps())
                        .rir(setRequest.getRir())
                        .restSeconds(setRequest.getRestSeconds() == null ? 90 : setRequest.getRestSeconds())
                        .completed(setRequest.getCompleted() == null || setRequest.getCompleted())
                        .build();

                session.getSets().add(set);
            }
        }

        var newPersonalRecords = workoutIntelligenceService.detectNewRecords(
                user, session
        );
        WorkoutSession savedSession = workoutSessionRepository.save(session);

        return workoutMapper.toWorkoutSessionResponse(
                savedSession, newPersonalRecords
        );
    }

    @Transactional(readOnly = true)
    public List<WorkoutSessionResponse> getMySessions(User user) {
        List<WorkoutSession> sessions = workoutSessionRepository.findByUserOrderBySessionDateDesc(user);

        return workoutMapper.toWorkoutSessionResponseList(sessions);
    }

    @Transactional(readOnly = true)
    public PageResponse<WorkoutSessionResponse> searchSessions(User user, int page, int size,
            java.time.LocalDate from, java.time.LocalDate to, String exerciseId) {
        var start = from == null ? java.time.LocalDate.of(1900, 1, 1) : from;
        var end = to == null ? java.time.LocalDate.of(9999, 12, 31) : to;
        if (start.isAfter(end)) throw new IllegalArgumentException("Ngày bắt đầu phải trước ngày kết thúc");
        return PageResponse.from(workoutSessionRepository.searchHistory(user, start, end,
                exerciseId == null ? "" : exerciseId,
                PageRequest.of(Math.max(0, page), Math.min(100, Math.max(1, size))))
                .map(workoutMapper::toWorkoutSessionResponse));
    }

    @Transactional
    public WorkoutSessionResponse replaceSession(User user, String sessionId, CreateWorkoutSessionRequest request) {
        validateGroups(request);
        WorkoutSession session = workoutSessionRepository.findByIdAndUser(sessionId, user)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy buổi tập"));
        // Resolve every exercise before changing the aggregate; an invalid ID cannot partially update history.
        var historicalIds = session.getSets().stream().map(set -> set.getExercise().getId())
                .collect(java.util.stream.Collectors.toSet());
        var historicalProvenance=session.getSets().stream().filter(s->s.getOriginalExerciseId()!=null)
                .map(s->s.getExercise().getId()+":"+s.getOriginalExerciseId()).collect(java.util.stream.Collectors.toSet());
        var resolved = request.getSets().stream().map(set -> {
            var exercise = exerciseRepository.findById(set.getExerciseId())
                    .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy bài tập"));
            if (!historicalIds.contains(exercise.getId())
                    && (!Boolean.TRUE.equals(exercise.getActive()) || !"APPROVED".equals(exercise.getApprovalStatus()))) {
                throw new IllegalArgumentException("Bài tập mới phải đang hoạt động và đã được duyệt");
            }
            if(set.getOriginalExerciseId()!=null&&!historicalProvenance.contains(exercise.getId()+":"+set.getOriginalExerciseId()))validateOriginal(user,set,exercise);
            return exercise;
        }).toList();
        session.setSessionDate(request.getSessionDate());
        session.setNote(request.getNote());
        session.setDurationMinutes(request.getDurationMinutes());
        session.getSets().clear();
        for (int i = 0; i < request.getSets().size(); i++) {
            var value = request.getSets().get(i);
            session.getSets().add(WorkoutSet.builder().session(session).exercise(resolved.get(i))
                        .originalExerciseId(value.getOriginalExerciseId())
                        .replacementKind(value.getReplacementKind())
                        .setNumber(value.getSetNumber()).exerciseOrder(value.getExerciseOrder() == null ? 1 : value.getExerciseOrder())
                        .groupKey(value.getGroupKey())
                        .groupType(value.getGroupType())
                        .groupRounds(value.getGroupRounds())
                        .betweenExerciseRestSeconds(value.getBetweenExerciseRestSeconds())
                        .betweenRoundRestSeconds(value.getBetweenRoundRestSeconds())
                    .setType(value.getSetType() == null ? com.fittrack.workout.entity.WorkoutSetType.NORMAL : value.getSetType())
                    .weight(value.getWeight()).reps(value.getReps()).rir(value.getRir())
                    .restSeconds(value.getRestSeconds() == null ? 90 : value.getRestSeconds()).completed(true).build());
        }
        return workoutMapper.toWorkoutSessionResponse(workoutSessionRepository.save(session));
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

    @Transactional(readOnly = true)
    public java.util.Optional<PreviousWorkoutPerformanceResponse> getPreviousPerformance(
            User user,
            String exerciseId
    ) {
        Exercise exercise = exerciseRepository.findById(exerciseId)
                .orElseThrow(() -> new IllegalArgumentException("Exercise not found"));
        return workoutSessionRepository.findLatestContainingExercise(
                        user,
                        exerciseId,
                        PageRequest.of(0, 1)
                ).stream()
                .findFirst()
                .map(session -> PreviousWorkoutPerformanceResponse.builder()
                        .exerciseId(exercise.getId())
                        .exerciseName(exercise.getName())
                        .sessionDate(session.getSessionDate())
                        .sets(session.getSets().stream()
                                .filter(set -> set.getExercise().getId().equals(exerciseId))
                                .sorted(java.util.Comparator.comparing(WorkoutSet::getSetNumber))
                                .map(workoutMapper::toWorkoutSetResponse)
                                .toList())
                        .build());
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

    private void validateGroups(CreateWorkoutSessionRequest request) {
        if(request.getSets()!=null&&request.getSets().stream().anyMatch(java.util.Objects::isNull))throw new IllegalArgumentException("Hiệp tập không hợp lệ");
        if (request.getSets() != null) com.fittrack.workoutplan.service.WorkoutGroups.validate(request.getSets().stream()
                .map(e -> new com.fittrack.workoutplan.service.WorkoutGroups.Group(e.getGroupKey(), e.getGroupType(),
                        e.getGroupRounds(), e.getBetweenExerciseRestSeconds(), e.getBetweenRoundRestSeconds())).toList());
    }
    private String validateOriginal(User user,CreateWorkoutSetRequest request,Exercise actual){
        var id=request.getOriginalExerciseId();
        if(request.getReplacementKind()!=null&&!java.util.Set.of("MANUAL","ALTERNATIVE").contains(request.getReplacementKind()))throw new IllegalArgumentException("Loại thay bài không hợp lệ");
        if(id==null)return null;
        var original=exerciseRepository.findById(id).orElseThrow(()->new IllegalArgumentException("Không tìm thấy bài dự kiến"));
        if("MANUAL".equals(request.getReplacementKind()))return id; // Explicit choice retains provenance; it is not an equivalent-exercise recommendation.
        if(!workoutIntelligenceService.isAllowedAlternative(user,original,actual))throw new IllegalArgumentException("Bài thay thế phải cùng nhóm cơ, được duyệt và không bị loại trừ");
        return id;
    }
}
