package com.fittrack.bodytracking.controller;

import com.fittrack.bodytracking.dto.ProgressPhotoDtos.ProgressPhotoRequest;
import com.fittrack.bodytracking.dto.ProgressPhotoDtos.ProgressPhotoResponse;
import com.fittrack.bodytracking.service.ProgressPhotoService;
import com.fittrack.common.media.MediaStorageService;
import com.fittrack.user.entity.User;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.net.URI;
import java.util.Base64;
import java.util.List;

@RestController
@RequestMapping("/api/progress-photos")
@RequiredArgsConstructor
public class ProgressPhotoController {
    private final ProgressPhotoService service;
    private final MediaStorageService mediaStorageService;

    @GetMapping
    public List<ProgressPhotoResponse> getMine(@AuthenticationPrincipal User user) {
        return service.getMine(user);
    }

    @PostMapping
    public ProgressPhotoResponse create(@AuthenticationPrincipal User user,
                                        @Valid @RequestBody ProgressPhotoRequest request) {
        return service.create(user, request);
    }

    @DeleteMapping("/{id}")
    public void delete(@AuthenticationPrincipal User user, @PathVariable String id) {
        service.delete(user, id);
    }

    @GetMapping("/{id}/image")
    public ResponseEntity<byte[]> image(@AuthenticationPrincipal User user, @PathVariable String id) {
        String value = service.storedImage(user, id);
        if (value.startsWith("https://")) {
            MediaStorageService.DownloadedImage image = mediaStorageService.downloadProtected(value);
            return ResponseEntity.ok().contentType(MediaType.parseMediaType(image.mimeType())).body(image.bytes());
        }
        int typeEnd = value.indexOf(';');
        int comma = value.indexOf(',');
        if (!value.startsWith("data:image/") || typeEnd < 5 || comma < typeEnd) {
            throw new IllegalArgumentException("Ảnh tiến độ không hợp lệ");
        }
        return ResponseEntity.ok()
                .contentType(MediaType.parseMediaType(value.substring(5, typeEnd)))
                .body(Base64.getDecoder().decode(value.substring(comma + 1)));
    }
}
