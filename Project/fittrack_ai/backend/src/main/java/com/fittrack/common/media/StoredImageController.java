package com.fittrack.common.media;

import com.fittrack.lunch.entity.LunchPaymentSettings;
import com.fittrack.lunch.repository.LunchMenuItemRepository;
import com.fittrack.lunch.repository.LunchPaymentSettingsRepository;
import com.fittrack.nutrition.repository.FoodRepository;
import com.fittrack.workout.repository.ExerciseRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.CacheControl;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

import java.net.URI;
import java.time.Duration;
import java.util.Base64;
import java.util.Set;

import static org.springframework.http.HttpStatus.NOT_FOUND;

@RestController
@RequestMapping("/api/media")
@RequiredArgsConstructor
public class StoredImageController {

    private static final Set<String> ALLOWED_MEDIA_TYPES = Set.of(
            "image/png",
            "image/jpeg",
            "image/webp",
            "image/gif",
            "image/avif"
    );

    private final LunchMenuItemRepository lunchMenuItemRepository;
    private final LunchPaymentSettingsRepository paymentSettingsRepository;
    private final FoodRepository foodRepository;
    private final ExerciseRepository exerciseRepository;
    private final MediaStorageService mediaStorageService;

    @GetMapping("/lunch-items/{id}")
    public ResponseEntity<byte[]> lunchItem(@PathVariable String id) {
        return imageResponse(lunchMenuItemRepository.findById(id)
                .map(item -> item.getImageUrl())
                .orElse(null));
    }

    @GetMapping("/foods/{id}")
    public ResponseEntity<byte[]> food(@PathVariable String id) {
        return imageResponse(foodRepository.findById(id)
                .map(food -> food.getImageUrl())
                .orElse(null));
    }

    @GetMapping("/exercises/{id}")
    public ResponseEntity<byte[]> exercise(@PathVariable String id) {
        return imageResponse(exerciseRepository.findById(id)
                .map(exercise -> exercise.getImageUrl())
                .orElse(null));
    }

    @GetMapping("/payment-qr")
    public ResponseEntity<byte[]> paymentQr() {
        String storedValue = paymentSettingsRepository
                .findById(LunchPaymentSettings.DEFAULT_ID)
                .map(LunchPaymentSettings::getQrImageUrl)
                .orElse(null);
        if (storedValue != null && storedValue.startsWith("https://")) {
            MediaStorageService.DownloadedImage image = mediaStorageService.downloadProtected(storedValue);
            return ResponseEntity.ok()
                    .header("X-Content-Type-Options", "nosniff")
                    .header("Cache-Control", "private, max-age=300")
                    .contentType(MediaType.parseMediaType(image.mimeType()))
                    .body(image.bytes());
        }
        return imageResponse(storedValue);
    }

    private ResponseEntity<byte[]> imageResponse(String storedValue) {
        if (storedValue == null || storedValue.isBlank()) {
            throw new ResponseStatusException(NOT_FOUND, "Không tìm thấy ảnh");
        }
        if (storedValue.startsWith("http://") || storedValue.startsWith("https://")) {
            return ResponseEntity.status(302)
                    .location(URI.create(storedValue))
                    .build();
        }

        int metadataEnd = storedValue.indexOf(',');
        int typeEnd = storedValue.indexOf(';');
        if (!storedValue.startsWith("data:")
                || metadataEnd < 0
                || typeEnd < 5
                || typeEnd > metadataEnd
                || !storedValue.substring(typeEnd, metadataEnd).equals(";base64")) {
            throw new ResponseStatusException(NOT_FOUND, "Ảnh không hợp lệ");
        }

        String mediaType = storedValue.substring(5, typeEnd).toLowerCase();
        if (!ALLOWED_MEDIA_TYPES.contains(mediaType)) {
            throw new ResponseStatusException(NOT_FOUND, "Định dạng ảnh không được hỗ trợ");
        }

        try {
            byte[] bytes = Base64.getDecoder().decode(storedValue.substring(metadataEnd + 1));
            return ResponseEntity.ok()
                    .header("X-Content-Type-Options", "nosniff")
                    .cacheControl(CacheControl.maxAge(Duration.ofDays(30)).cachePublic())
                    .contentType(MediaType.parseMediaType(mediaType))
                    .body(bytes);
        } catch (IllegalArgumentException exception) {
            throw new ResponseStatusException(NOT_FOUND, "Ảnh không hợp lệ", exception);
        }
    }
}
