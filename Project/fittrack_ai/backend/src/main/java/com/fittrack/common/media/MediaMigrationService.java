package com.fittrack.common.media;

import com.fittrack.lunch.entity.LunchMenuItem;
import com.fittrack.lunch.entity.LunchPaymentSettings;
import com.fittrack.lunch.repository.LunchMenuItemRepository;
import com.fittrack.lunch.repository.LunchPaymentSettingsRepository;
import com.fittrack.nutrition.entity.Food;
import com.fittrack.nutrition.repository.FoodRepository;
import com.fittrack.workout.entity.Exercise;
import com.fittrack.workout.repository.ExerciseRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.function.Consumer;

@Service
@RequiredArgsConstructor
public class MediaMigrationService {

    private final MediaStorageService mediaStorageService;
    private final FoodRepository foodRepository;
    private final ExerciseRepository exerciseRepository;
    private final LunchMenuItemRepository lunchMenuItemRepository;
    private final LunchPaymentSettingsRepository lunchPaymentSettingsRepository;

    public MigrationResult migrate(int requestedLimit) {
        if (!mediaStorageService.usesCloudinary()) {
            throw new IllegalStateException("MEDIA_PROVIDER phải là cloudinary trước khi di chuyển ảnh");
        }
        int limit = Math.min(Math.max(requestedLimit, 1), 100);
        Counter counter = new Counter(limit);

        migrateFoods(counter);
        migrateExercises(counter);
        migrateLunchItems(counter);
        migratePaymentQr(counter);

        return new MigrationResult(counter.migrated, counter.remaining, counter.failures);
    }

    private void migrateFoods(Counter counter) {
        for (Food item : foodRepository.findAll()) {
            migrateOne(counter, item.getImageUrl(), "foods", item.getId(), url -> {
                item.setImageUrl(url);
                foodRepository.save(item);
            });
        }
    }

    private void migrateExercises(Counter counter) {
        for (Exercise item : exerciseRepository.findAll()) {
            migrateOne(counter, item.getImageUrl(), "exercises", item.getId(), url -> {
                item.setImageUrl(url);
                exerciseRepository.save(item);
            });
        }
    }

    private void migrateLunchItems(Counter counter) {
        for (LunchMenuItem item : lunchMenuItemRepository.findAll()) {
            migrateOne(counter, item.getImageUrl(), "lunch-items", item.getId(), url -> {
                item.setImageUrl(url);
                lunchMenuItemRepository.save(item);
            });
        }
    }

    private void migratePaymentQr(Counter counter) {
        for (LunchPaymentSettings item : lunchPaymentSettingsRepository.findAll()) {
            migrateOne(counter, item.getQrImageUrl(), "payment-qr", item.getId(), url -> {
                item.setQrImageUrl(url);
                lunchPaymentSettingsRepository.save(item);
            });
        }
    }

    private void migrateOne(
            Counter counter,
            String storedValue,
            String folder,
            String objectId,
            Consumer<String> save
    ) {
        if (storedValue == null || !storedValue.startsWith("data:image/")) return;
        if (counter.migrated >= counter.limit) {
            counter.remaining++;
            return;
        }
        try {
            save.accept(mediaStorageService.storeNew(storedValue, folder, objectId));
            counter.migrated++;
        } catch (RuntimeException exception) {
            counter.remaining++;
            counter.failures.add(folder + "/" + objectId + ": " + safeMessage(exception));
        }
    }

    private String safeMessage(RuntimeException exception) {
        String message = exception.getMessage();
        return message == null || message.isBlank() ? exception.getClass().getSimpleName() : message;
    }

    private static final class Counter {
        private final int limit;
        private int migrated;
        private int remaining;
        private final List<String> failures = new ArrayList<>();

        private Counter(int limit) {
            this.limit = limit;
        }
    }

    public record MigrationResult(int migrated, int remaining, List<String> failures) {
    }
}
