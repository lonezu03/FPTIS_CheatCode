package com.fittrack.workout.service;

import com.fittrack.workout.dto.CreateExerciseRequest;
import com.fittrack.workout.dto.ExerciseResponse;
import com.fittrack.workout.dto.UpdateExerciseRequest;
import com.fittrack.workout.entity.Exercise;
import com.fittrack.workout.mapper.WorkoutMapper;
import com.fittrack.workout.repository.ExerciseRepository;
import com.fittrack.common.media.ImageReferences;
import com.fittrack.common.dto.CatalogReviewRequest;
import com.fittrack.lunch.service.LunchNotificationService;
import com.fittrack.user.entity.User;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.time.LocalDateTime;

@Service
@RequiredArgsConstructor
public class ExerciseService {

    private final ExerciseRepository exerciseRepository;
    private final WorkoutMapper workoutMapper;
    private final LunchNotificationService notificationService;

    public List<ExerciseResponse> getExercises(String keyword, Boolean includeInactive) {
        boolean showInactive = Boolean.TRUE.equals(includeInactive);

        List<Exercise> exercises;

        if (showInactive) {
            if (keyword == null || keyword.isBlank()) {
                exercises = exerciseRepository.findAllByOrderByNameAsc();
            } else {
                exercises = exerciseRepository.findByNameContainingIgnoreCaseOrderByNameAsc(keyword);
            }
        } else {
            if (keyword == null || keyword.isBlank()) {
                exercises = exerciseRepository.findByActiveTrueOrderByNameAsc();
            } else {
                exercises = exerciseRepository.findByActiveTrueAndNameContainingIgnoreCaseOrderByNameAsc(keyword);
            }
        }

        return workoutMapper.toExerciseResponseList(exercises);
    }

    public ExerciseResponse create(CreateExerciseRequest request) {
        Exercise exercise = Exercise.builder()
                .name(request.getName())
                .muscleGroup(request.getMuscleGroup())
                .equipment(request.getEquipment())
                .description(request.getDescription())
                .imageUrl(ImageReferences.normalizeForStorage(request.getImageUrl()))
                .custom(true)
                .active(true)
                .approvalStatus("APPROVED")
                .build();

        Exercise saved = exerciseRepository.save(exercise);

        return workoutMapper.toExerciseResponse(saved);
    }

    public ExerciseResponse createSuggestion(
            User user,
            CreateExerciseRequest request
    ) {
        Exercise exercise = Exercise.builder()
                .name(request.getName().trim())
                .muscleGroup(request.getMuscleGroup())
                .equipment(request.getEquipment())
                .description(request.getDescription())
                .imageUrl(
                        ImageReferences.normalizeForStorage(
                                request.getImageUrl()
                        )
                )
                .custom(true)
                .active(false)
                .approvalStatus("PENDING")
                .submittedBy(user)
                .build();
        Exercise saved = exerciseRepository.save(exercise);
        notificationService.notifyAdmins(
                "CATALOG_SUBMISSION",
                "Có bài tập mới chờ duyệt",
                user.getFullName() + " đã gửi bài tập " + saved.getName(),
                "EXERCISE",
                saved.getId()
        );
        return workoutMapper.toExerciseResponse(saved);
    }

    public List<ExerciseResponse> getMySubmissions(User user) {
        return workoutMapper.toExerciseResponseList(
                exerciseRepository.findBySubmittedByOrderByCreatedAtDesc(user)
        );
    }

    public ExerciseResponse review(
            String id,
            CatalogReviewRequest request
    ) {
        Exercise exercise = exerciseRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException(
                        "Không tìm thấy bài tập"
                ));
        if (!"PENDING".equals(exercise.getApprovalStatus())) {
            throw new IllegalArgumentException(
                    "Bài tập này đã được xử lý trước đó"
            );
        }
        exercise.setApprovalStatus(request.status());
        exercise.setAdminNote(
                request.note() == null ? null : request.note().trim()
        );
        exercise.setReviewedAt(LocalDateTime.now());
        exercise.setActive("APPROVED".equals(request.status()));
        Exercise saved = exerciseRepository.save(exercise);
        if (saved.getSubmittedBy() != null) {
            notificationService.notifyUser(
                    saved.getSubmittedBy(),
                    "CATALOG_REVIEW",
                    "Kết quả duyệt bài tập",
                    "Bài tập " + saved.getName() + " đã "
                            + ("APPROVED".equals(request.status())
                            ? "được duyệt"
                            : "bị từ chối"),
                    "EXERCISE",
                    saved.getId()
            );
        }
        return workoutMapper.toExerciseResponse(saved);
    }

    public ExerciseResponse update(String id, UpdateExerciseRequest request) {
        Exercise exercise = exerciseRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Exercise not found"));

        exercise.setName(request.getName());
        exercise.setMuscleGroup(request.getMuscleGroup());
        exercise.setEquipment(request.getEquipment());
        exercise.setDescription(request.getDescription());
        exercise.setImageUrl(ImageReferences.resolveStoredValue(
                exercise.getImageUrl(),
                request.getImageUrl(),
                ImageReferences.exercisePath(exercise.getId())
        ));

        Exercise saved = exerciseRepository.save(exercise);

        return workoutMapper.toExerciseResponse(saved);
    }

    public void softDelete(String id) {
        Exercise exercise = exerciseRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Exercise not found"));

        exercise.setActive(false);

        exerciseRepository.save(exercise);
    }

    public ExerciseResponse restore(String id) {
        Exercise exercise = exerciseRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Exercise not found"));

        exercise.setActive(true);

        Exercise saved = exerciseRepository.save(exercise);

        return workoutMapper.toExerciseResponse(saved);
    }
}

