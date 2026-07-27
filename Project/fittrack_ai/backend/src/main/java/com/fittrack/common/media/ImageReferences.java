package com.fittrack.common.media;

public final class ImageReferences {

    private static final String MEDIA_ROOT = "/api/media";
    private static final java.util.Set<String> ALLOWED_DATA_PREFIXES = java.util.Set.of(
            "data:image/png;base64,",
            "data:image/jpeg;base64,",
            "data:image/webp;base64,",
            "data:image/gif;base64,",
            "data:image/avif;base64,"
    );

    private ImageReferences() {
    }

    public static String lunchItemPath(String id) {
        return MEDIA_ROOT + "/lunch-items/" + id;
    }

    public static String foodPath(String id) {
        return MEDIA_ROOT + "/foods/" + id;
    }

    public static String exercisePath(String id) {
        return MEDIA_ROOT + "/exercises/" + id;
    }

    public static String paymentQrPath() {
        return MEDIA_ROOT + "/payment-qr";
    }

    public static String responseUrl(String storedValue, String mediaPath) {
        if (storedValue == null || storedValue.isBlank()) {
            return null;
        }
        if (!storedValue.startsWith("data:image/")) {
            return storedValue;
        }
        return mediaPath + "?v=" + Integer.toUnsignedString(storedValue.hashCode(), 36);
    }

    public static String resolveStoredValue(
            String currentValue,
            String requestedValue,
            String mediaPath
    ) {
        if (requestedValue == null || requestedValue.isBlank()) {
            return null;
        }
        String trimmed = requestedValue.trim();
        if (trimmed.equals(mediaPath) || trimmed.startsWith(mediaPath + "?")) {
            return currentValue;
        }
        return normalizeForStorage(trimmed);
    }

    public static String normalizeForStorage(String requestedValue) {
        if (requestedValue == null || requestedValue.isBlank()) {
            return null;
        }
        String trimmed = requestedValue.trim();
        if (trimmed.startsWith("https://") || trimmed.startsWith("http://")) {
            return trimmed;
        }
        boolean supportedDataImage = ALLOWED_DATA_PREFIXES.stream()
                .anyMatch(trimmed::startsWith);
        if (!supportedDataImage) {
            throw new IllegalArgumentException(
                    "Ảnh phải là URL http(s) hoặc file PNG, JPEG, WebP, GIF, AVIF"
            );
        }
        return trimmed;
    }
}
