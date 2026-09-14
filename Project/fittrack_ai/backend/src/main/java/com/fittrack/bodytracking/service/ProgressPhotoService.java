package com.fittrack.bodytracking.service;

import com.fittrack.bodytracking.dto.ProgressPhotoDtos.ProgressPhotoRequest;
import com.fittrack.bodytracking.dto.ProgressPhotoDtos.ProgressPhotoResponse;
import com.fittrack.bodytracking.entity.ProgressPhoto;
import com.fittrack.bodytracking.repository.ProgressPhotoRepository;
import com.fittrack.common.exception.ResourceNotFoundException;
import com.fittrack.common.media.MediaStorageService;
import com.fittrack.user.entity.User;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;
import java.util.Set;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class ProgressPhotoService {
    private static final Set<String> POSES = Set.of("FRONT", "SIDE", "BACK", "OTHER");
    private final ProgressPhotoRepository repository;
    private final MediaStorageService mediaStorageService;

    @Transactional(readOnly = true)
    public List<ProgressPhotoResponse> getMine(User user) {
        return repository.findByUserOrderByTakenDateDescCreatedAtDesc(user).stream()
                .map(this::toResponse).toList();
    }

    @Transactional
    public ProgressPhotoResponse create(User user, ProgressPhotoRequest request) {
        String id = UUID.randomUUID().toString();
        ProgressPhoto photo = ProgressPhoto.builder()
                .id(id)
                .user(user)
                .imageUrl(mediaStorageService.storeNew(request.imageUrl(), "progress-photos", id))
                .takenDate(request.takenDate() == null ? LocalDate.now() : request.takenDate())
                .pose(normalizePose(request.pose()))
                .note(trim(request.note()))
                .weight(request.weight())
                .build();
        return toResponse(repository.save(photo));
    }

    @Transactional
    public void delete(User user, String id) {
        repository.delete(find(user, id));
    }

    @Transactional(readOnly = true)
    public String storedImage(User user, String id) {
        return find(user, id).getImageUrl();
    }

    private ProgressPhoto find(User user, String id) {
        return repository.findByIdAndUser(id, user)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy ảnh tiến độ"));
    }

    private ProgressPhotoResponse toResponse(ProgressPhoto photo) {
        return new ProgressPhotoResponse(photo.getId(), "/api/progress-photos/" + photo.getId() + "/image",
                photo.getTakenDate(), photo.getPose(), photo.getNote(), photo.getWeight(), photo.getCreatedAt());
    }

    private String normalizePose(String value) {
        String pose = value == null || value.isBlank() ? "OTHER" : value.trim().toUpperCase();
        if (!POSES.contains(pose)) throw new IllegalArgumentException("Góc chụp không hợp lệ");
        return pose;
    }

    private String trim(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }
}
