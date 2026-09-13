package com.fittrack.workout.service;

import com.fittrack.user.entity.User;
import com.fittrack.workout.dto.PreviousWorkoutPerformanceResponse;
import com.fittrack.workout.dto.WorkoutIntelligenceDtos.AlternativeExerciseResponse;
import com.fittrack.workout.dto.WorkoutIntelligenceDtos.ExercisePreferenceResponse;
import com.fittrack.workout.dto.WorkoutIntelligenceDtos.MuscleVolumeResponse;
import com.fittrack.workout.dto.WorkoutIntelligenceDtos.NewPersonalRecordResponse;
import com.fittrack.workout.dto.WorkoutIntelligenceDtos.PersonalBestResponse;
import com.fittrack.workout.dto.WorkoutIntelligenceDtos.ProgressionResponse;
import com.fittrack.workout.dto.WorkoutIntelligenceDtos.WeeklyVolumeResponse;
import com.fittrack.workout.dto.WorkoutIntelligenceDtos.WorkoutIntelligenceResponse;
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
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.temporal.TemporalAdjusters;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.function.ToDoubleFunction;

@Service
@RequiredArgsConstructor
public class WorkoutIntelligenceService {

    private static final String DISCLAIMER =
            "Số liệu được ước tính từ các set đã hoàn thành; không phải đánh giá y khoa.";
    private static final ZoneId VIETNAM_ZONE = ZoneId.of("Asia/Ho_Chi_Minh");

    private final ExerciseRepository exerciseRepository;
    private final ExercisePreferenceRepository preferenceRepository;
    private final WorkoutSessionRepository sessionRepository;
    private final WorkoutSetRepository setRepository;
    private final WorkoutMapper workoutMapper;

    @Transactional(readOnly = true)
    public WorkoutIntelligenceResponse getIntelligence(
            User user,
            String exerciseId,
            int targetSets,
            int minReps,
            int maxReps,
            int targetRir
    ) {
        Exercise exercise = requireExercise(exerciseId);
        int safeSets = clamp(targetSets, 1, 20);
        int safeMinReps = clamp(minReps, 1, 100);
        int safeMaxReps = clamp(maxReps, safeMinReps, 100);
        int safeRir = clamp(targetRir, 0, 5);

        WorkoutSession previousSession = sessionRepository.findLatestContainingExercise(
                user, exerciseId, PageRequest.of(0, 1)
        ).stream().findFirst().orElse(null);
        PreviousWorkoutPerformanceResponse previous = previousSession == null
                ? null
                : PreviousWorkoutPerformanceResponse.builder()
                .exerciseId(exercise.getId())
                .exerciseName(exercise.getName())
                .sessionDate(previousSession.getSessionDate())
                .sets(previousSession.getSets().stream()
                        .filter(set -> set.getExercise().getId().equals(exerciseId))
                        .filter(set -> Boolean.TRUE.equals(set.getCompleted()))
                        .sorted(Comparator.comparing(WorkoutSet::getSetNumber))
                        .map(workoutMapper::toWorkoutSetResponse)
                        .toList())
                .build();

        List<WorkoutSet> history = setRepository.findCompletedByUserAndExercise(
                user, exerciseId
        );
        ProgressionResponse progression = progression(
                exercise,
                previousSession == null ? List.of() : previousSession.getSets(),
                safeSets,
                safeMinReps,
                safeMaxReps,
                safeRir
        );
        return new WorkoutIntelligenceResponse(
                exercise.getId(),
                exercise.getName(),
                previous,
                progression,
                personalBests(history)
        );
    }

    @Transactional(readOnly = true)
    public WeeklyVolumeResponse getWeeklyVolume(User user, LocalDate requestedStart) {
        LocalDate weekStart = (requestedStart == null
                ? LocalDate.now(VIETNAM_ZONE)
                : requestedStart)
                .with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY));
        LocalDate weekEnd = weekStart.plusDays(6);
        LocalDate previousStart = weekStart.minusWeeks(1);
        LocalDate previousEnd = weekStart.minusDays(1);

        List<WorkoutSet> current = workingSets(setRepository
                .findCompletedByUserAndDateBetween(user, weekStart, weekEnd));
        List<WorkoutSet> previous = workingSets(setRepository
                .findCompletedByUserAndDateBetween(user, previousStart, previousEnd));
        Map<String, VolumeAccumulator> currentByMuscle = volumeByMuscle(current);
        Map<String, VolumeAccumulator> previousByMuscle = volumeByMuscle(previous);

        Set<String> groups = new LinkedHashSet<>();
        groups.addAll(currentByMuscle.keySet());
        groups.addAll(previousByMuscle.keySet());

        List<MuscleVolumeResponse> rows = groups.stream()
                .map(group -> {
                    VolumeAccumulator now = currentByMuscle.getOrDefault(
                            group, new VolumeAccumulator()
                    );
                    VolumeAccumulator before = previousByMuscle.getOrDefault(
                            group, new VolumeAccumulator()
                    );
                    return new MuscleVolumeResponse(
                            group,
                            now.sets,
                            before.sets,
                            roundOne(now.volume),
                            now.sets - before.sets
                    );
                })
                .sorted(Comparator
                        .comparingInt(MuscleVolumeResponse::workingSets)
                        .reversed()
                        .thenComparing(MuscleVolumeResponse::muscleGroup))
                .toList();

        return new WeeklyVolumeResponse(
                weekStart,
                weekEnd,
                current.size(),
                roundOne(current.stream().mapToDouble(this::setVolume).sum()),
                rows,
                DISCLAIMER
        );
    }

    @Transactional(readOnly = true)
    public List<ExercisePreferenceResponse> getPreferences(User user) {
        return preferenceRepository.findByUser(user).stream()
                .map(value -> new ExercisePreferenceResponse(
                        value.getExercise().getId(), value.getPreference()
                ))
                .toList();
    }

    @Transactional
    public ExercisePreferenceResponse setPreference(
            User user,
            String exerciseId,
            ExercisePreferenceLevel level
    ) {
        Exercise exercise = requireExercise(exerciseId);
        ExercisePreference preference = preferenceRepository
                .findByUserAndExerciseId(user, exerciseId)
                .orElseGet(() -> ExercisePreference.builder()
                        .user(user)
                        .exercise(exercise)
                        .build());
        preference.setPreference(level);
        ExercisePreference saved = preferenceRepository.save(preference);
        return new ExercisePreferenceResponse(exerciseId, saved.getPreference());
    }

    @Transactional(readOnly = true)
    public List<AlternativeExerciseResponse> getAlternatives(
            User user,
            String exerciseId
    ) {
        Exercise source = requireExercise(exerciseId);
        Map<String, ExercisePreferenceLevel> preferences = preferenceMap(user);
        String sourceMuscle = normalize(source.getMuscleGroup());
        String sourceEquipment = normalize(source.getEquipment());

        return exerciseRepository.findByActiveTrueOrderByNameAsc().stream()
                .filter(candidate -> !candidate.getId().equals(exerciseId))
                .filter(candidate -> "APPROVED".equals(candidate.getApprovalStatus()))
                .filter(candidate -> normalize(candidate.getMuscleGroup()).equals(sourceMuscle))
                .filter(candidate -> preferences.getOrDefault(
                        candidate.getId(), ExercisePreferenceLevel.NORMAL
                ) != ExercisePreferenceLevel.EXCLUDED)
                .map(candidate -> new AlternativeExerciseResponse(
                        workoutMapper.toExerciseResponse(candidate),
                        preferences.getOrDefault(
                                candidate.getId(), ExercisePreferenceLevel.NORMAL
                        ),
                        normalize(candidate.getEquipment()).equals(sourceEquipment)
                ))
                .sorted(Comparator
                        .comparingInt((AlternativeExerciseResponse value) ->
                                preferenceRank(value.preference()))
                        .thenComparing(value -> !value.sameEquipment())
                        .thenComparing(value -> value.exercise().getName()))
                .limit(12)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<NewPersonalRecordResponse> detectNewRecords(
            User user,
            WorkoutSession candidateSession
    ) {
        Map<String, List<WorkoutSet>> candidateByExercise = new LinkedHashMap<>();
        for (WorkoutSet set : workingSets(candidateSession.getSets())) {
            candidateByExercise.computeIfAbsent(
                    set.getExercise().getId(), ignored -> new ArrayList<>()
            ).add(set);
        }

        List<NewPersonalRecordResponse> records = new ArrayList<>();
        for (Map.Entry<String, List<WorkoutSet>> entry : candidateByExercise.entrySet()) {
            String exerciseId = entry.getKey();
            List<WorkoutSet> candidate = entry.getValue();
            List<WorkoutSet> history = workingSets(
                    setRepository.findCompletedByUserAndExercise(user, exerciseId)
            );
            String exerciseName = candidate.get(0).getExercise().getName();

            addMaxRecord(records, "HEAVIEST_WEIGHT", exerciseId, exerciseName,
                    history, candidate, this::weight, "kg");
            addMaxRecord(records, "ESTIMATED_1RM", exerciseId, exerciseName,
                    history.stream().filter(this::supportsE1rm).toList(),
                    candidate.stream().filter(this::supportsE1rm).toList(),
                    this::estimatedOneRepMax, "kg e1RM");

            WorkoutSet candidateRepSet = candidate.stream()
                    .max(Comparator.comparingInt(WorkoutSet::getReps)
                            .thenComparingDouble(this::weight))
                    .orElse(null);
            if (candidateRepSet != null) {
                double candidateWeight = weight(candidateRepSet);
                double previousReps = history.stream()
                        .filter(set -> Double.compare(weight(set), candidateWeight) == 0)
                        .mapToInt(WorkoutSet::getReps)
                        .max()
                        .orElse(0);
                if (candidateRepSet.getReps() > previousReps) {
                    records.add(new NewPersonalRecordResponse(
                            "MAX_REPS_AT_WEIGHT", exerciseId, exerciseName,
                            previousReps == 0 ? null : previousReps,
                            candidateRepSet.getReps().doubleValue(),
                            candidateWeight,
                            candidateRepSet.getReps(),
                            "reps"
                    ));
                }
            }

            double candidateVolume = candidate.stream()
                    .mapToDouble(this::setVolume).sum();
            double previousVolume = maxSessionVolume(history);
            if (candidateVolume > 0 && candidateVolume > previousVolume) {
                records.add(new NewPersonalRecordResponse(
                        "MAX_SESSION_VOLUME", exerciseId, exerciseName,
                        previousVolume == 0 ? null : roundOne(previousVolume),
                        roundOne(candidateVolume), null, null, "kg volume"
                ));
            }
        }
        return records;
    }

    private ProgressionResponse progression(
            Exercise exercise,
            List<WorkoutSet> previousSessionSets,
            int targetSets,
            int minReps,
            int maxReps,
            int targetRir
    ) {
        List<WorkoutSet> work = workingSets(previousSessionSets).stream()
                .filter(set -> set.getExercise().getId().equals(exercise.getId()))
                .filter(set -> set.getSetType() == WorkoutSetType.NORMAL)
                .toList();
        if (work.isEmpty()) {
            work = workingSets(previousSessionSets).stream()
                    .filter(set -> set.getExercise().getId().equals(exercise.getId()))
                    .toList();
        }
        if (work.isEmpty()) {
            return new ProgressionResponse(
                    "NO_DATA", null, null, targetSets, minReps, maxReps,
                    targetRir,
                    "Chưa có set làm việc trước đó. Hãy bắt đầu với mức tải bạn kiểm soát tốt kỹ thuật.",
                    false
            );
        }

        double baseWeight = work.stream().mapToDouble(this::weight).max().orElse(0);
        double averageReps = work.stream().mapToInt(WorkoutSet::getReps).average().orElse(0);
        double averageRir = work.stream().mapToInt(WorkoutSet::getRir).average().orElse(0);
        boolean completedTargetSets = work.size() >= targetSets;
        boolean reachedTop = completedTargetSets && work.stream().limit(targetSets)
                .allMatch(set -> set.getReps() >= maxReps && set.getRir() >= targetRir);

        if (reachedTop && baseWeight > 0) {
            double nextWeight = increaseWeight(baseWeight, exercise.getEquipment());
            return new ProgressionResponse(
                    "INCREASE_WEIGHT", baseWeight, nextWeight, targetSets,
                    minReps, maxReps, targetRir,
                    "Bạn đã đạt đầu trên của khoảng reps với RIR còn đủ. Tăng tải nhẹ và quay lại đầu khoảng reps.",
                    true
            );
        }
        if (averageReps < minReps || averageRir <= 0.5) {
            double nextWeight = baseWeight <= 0
                    ? baseWeight
                    : decreaseWeight(baseWeight, exercise.getEquipment());
            return new ProgressionResponse(
                    "DECREASE_OR_HOLD", baseWeight, nextWeight, targetSets,
                    minReps, maxReps, targetRir,
                    "Reps hoặc RIR lần trước thấp hơn mục tiêu. Ưu tiên kỹ thuật; giảm nhẹ nếu mức tải cũ vẫn quá nặng.",
                    completedTargetSets
            );
        }

        int nextRepTarget = clamp((int) Math.floor(averageReps) + 1, minReps, maxReps);
        return new ProgressionResponse(
                "BUILD_REPS", baseWeight, baseWeight, targetSets,
                nextRepTarget, maxReps, targetRir,
                "Giữ mức tải và tăng dần reps cho tới khi tất cả set chạm đầu trên của khoảng mục tiêu.",
                completedTargetSets
        );
    }

    private List<PersonalBestResponse> personalBests(List<WorkoutSet> rawHistory) {
        List<WorkoutSet> history = workingSets(rawHistory);
        if (history.isEmpty()) {
            return List.of();
        }
        List<PersonalBestResponse> result = new ArrayList<>();
        history.stream().max(Comparator.comparingDouble(this::weight)).ifPresent(set ->
                result.add(new PersonalBestResponse(
                        "HEAVIEST_WEIGHT", roundOne(weight(set)), weight(set),
                        set.getReps(), set.getSession().getSessionDate()
                )));
        history.stream().filter(this::supportsE1rm)
                .max(Comparator.comparingDouble(this::estimatedOneRepMax))
                .ifPresent(set -> result.add(new PersonalBestResponse(
                        "ESTIMATED_1RM", roundOne(estimatedOneRepMax(set)),
                        weight(set), set.getReps(), set.getSession().getSessionDate()
                )));
        history.stream().max(Comparator.comparingInt(WorkoutSet::getReps)
                        .thenComparingDouble(this::weight))
                .ifPresent(set -> result.add(new PersonalBestResponse(
                        "MAX_REPS_AT_WEIGHT", set.getReps().doubleValue(),
                        weight(set), set.getReps(), set.getSession().getSessionDate()
                )));
        double maxVolume = maxSessionVolume(history);
        if (maxVolume > 0) {
            result.add(new PersonalBestResponse(
                    "MAX_SESSION_VOLUME", roundOne(maxVolume), null, null,
                    sessionDateForMaxVolume(history)
            ));
        }
        return result;
    }

    private void addMaxRecord(
            List<NewPersonalRecordResponse> records,
            String type,
            String exerciseId,
            String exerciseName,
            List<WorkoutSet> history,
            List<WorkoutSet> candidate,
            ToDoubleFunction<WorkoutSet> metric,
            String unit
    ) {
        WorkoutSet best = candidate.stream()
                .max(Comparator.comparingDouble(metric)).orElse(null);
        if (best == null) {
            return;
        }
        double newValue = metric.applyAsDouble(best);
        double previousValue = history.stream().mapToDouble(metric).max().orElse(0);
        if (newValue > 0 && newValue > previousValue) {
            records.add(new NewPersonalRecordResponse(
                    type, exerciseId, exerciseName,
                    previousValue == 0 ? null : roundOne(previousValue),
                    roundOne(newValue), weight(best), best.getReps(), unit
            ));
        }
    }

    private Map<String, VolumeAccumulator> volumeByMuscle(List<WorkoutSet> sets) {
        Map<String, VolumeAccumulator> result = new HashMap<>();
        for (WorkoutSet set : sets) {
            String group = displayMuscle(set.getExercise().getMuscleGroup());
            VolumeAccumulator accumulator = result.computeIfAbsent(
                    group, ignored -> new VolumeAccumulator()
            );
            accumulator.sets++;
            accumulator.volume += setVolume(set);
        }
        return result;
    }

    private Map<String, ExercisePreferenceLevel> preferenceMap(User user) {
        Map<String, ExercisePreferenceLevel> result = new HashMap<>();
        for (ExercisePreference value : preferenceRepository.findByUser(user)) {
            result.put(value.getExercise().getId(), value.getPreference());
        }
        return result;
    }

    private List<WorkoutSet> workingSets(List<WorkoutSet> sets) {
        return sets.stream()
                .filter(set -> Boolean.TRUE.equals(set.getCompleted()))
                .filter(set -> set.getSetType() != WorkoutSetType.WARMUP)
                .filter(set -> set.getReps() != null && set.getReps() > 0)
                .toList();
    }

    private double maxSessionVolume(List<WorkoutSet> sets) {
        return sets.stream().collect(java.util.stream.Collectors.groupingBy(
                        set -> set.getSession().getId(),
                        java.util.stream.Collectors.summingDouble(this::setVolume)
                )).values().stream().mapToDouble(Double::doubleValue).max().orElse(0);
    }

    private LocalDate sessionDateForMaxVolume(List<WorkoutSet> sets) {
        return sets.stream().collect(java.util.stream.Collectors.groupingBy(
                        set -> set.getSession(),
                        java.util.stream.Collectors.summingDouble(this::setVolume)
                )).entrySet().stream()
                .max(Map.Entry.comparingByValue())
                .map(entry -> entry.getKey().getSessionDate())
                .orElse(null);
    }

    private double setVolume(WorkoutSet set) {
        return weight(set) * (set.getReps() == null ? 0 : set.getReps());
    }

    private double weight(WorkoutSet set) {
        return set.getWeight() == null ? 0 : set.getWeight();
    }

    private boolean supportsE1rm(WorkoutSet set) {
        return weight(set) > 0 && set.getReps() != null
                && set.getReps() >= 1 && set.getReps() <= 30;
    }

    private double estimatedOneRepMax(WorkoutSet set) {
        return weight(set) * (1 + set.getReps() / 30.0);
    }

    private double increaseWeight(double weight, String equipment) {
        double increment = weightIncrement(equipment);
        return roundOne(Math.ceil((weight * 1.025) / increment) * increment);
    }

    private double decreaseWeight(double weight, String equipment) {
        double increment = weightIncrement(equipment);
        return roundOne(Math.max(0, Math.floor((weight * 0.95) / increment) * increment));
    }

    private double weightIncrement(String equipment) {
        String value = normalize(equipment);
        if (value.contains("dumbbell") || value.contains("ta don")) {
            return 2;
        }
        if (value.contains("machine") || value.contains("cable")
                || value.contains("may")) {
            return 5;
        }
        return 2.5;
    }

    private int preferenceRank(ExercisePreferenceLevel level) {
        return switch (level) {
            case FAVORITE -> 0;
            case NORMAL -> 1;
            case LESS -> 2;
            case EXCLUDED -> 3;
        };
    }

    private Exercise requireExercise(String exerciseId) {
        return exerciseRepository.findById(exerciseId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy bài tập"));
    }

    private String displayMuscle(String value) {
        return value == null || value.isBlank() ? "Khác" : value.trim();
    }

    private String normalize(String value) {
        if (value == null) {
            return "";
        }
        return java.text.Normalizer.normalize(value, java.text.Normalizer.Form.NFD)
                .replaceAll("\\p{M}", "")
                .trim()
                .toLowerCase(Locale.ROOT);
    }

    private int clamp(int value, int min, int max) {
        return Math.max(min, Math.min(value, max));
    }

    private double roundOne(double value) {
        return Math.round(value * 10.0) / 10.0;
    }

    private static final class VolumeAccumulator {
        private int sets;
        private double volume;
    }
}
