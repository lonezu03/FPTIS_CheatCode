package com.fittrack.common.media;

import org.springframework.stereotype.Component;

import javax.imageio.ImageIO;
import java.io.ByteArrayInputStream;
import java.util.Base64;
import java.util.Map;

@Component
public class ImageValidator {

    private static final int MAX_BYTES = 1_500_000;
    private static final int MAX_DIMENSION = 4096;
    private static final Map<String, String> MIME_PREFIXES = Map.of(
            "image/png", "data:image/png;base64,",
            "image/jpeg", "data:image/jpeg;base64,",
            "image/webp", "data:image/webp;base64,",
            "image/gif", "data:image/gif;base64,",
            "image/avif", "data:image/avif;base64,"
    );

    public ValidatedImage validateDataUri(String value) {
        String mimeType = MIME_PREFIXES.entrySet().stream()
                .filter(entry -> value.startsWith(entry.getValue()))
                .map(Map.Entry::getKey)
                .findFirst()
                .orElseThrow(() -> new IllegalArgumentException(
                        "Ảnh phải là PNG, JPEG, WebP, GIF hoặc AVIF"
                ));
        int comma = value.indexOf(',');
        byte[] bytes;
        try {
            bytes = Base64.getDecoder().decode(value.substring(comma + 1));
        } catch (IllegalArgumentException exception) {
            throw new IllegalArgumentException("Dữ liệu ảnh Base64 không hợp lệ", exception);
        }
        if (bytes.length == 0 || bytes.length > MAX_BYTES) {
            throw new IllegalArgumentException("Ảnh phải nhỏ hơn 1,5 MB");
        }
        if (!matchesMagic(mimeType, bytes)) {
            throw new IllegalArgumentException("Nội dung file không khớp định dạng ảnh đã khai báo");
        }
        validateDimensionsWhenSupported(mimeType, bytes);
        return new ValidatedImage(mimeType, bytes, value);
    }

    private void validateDimensionsWhenSupported(String mimeType, byte[] bytes) {
        if ("image/webp".equals(mimeType) || "image/avif".equals(mimeType)) return;
        try {
            var image = ImageIO.read(new ByteArrayInputStream(bytes));
            if (image == null || image.getWidth() <= 0 || image.getHeight() <= 0) {
                throw new IllegalArgumentException("Không thể đọc kích thước ảnh");
            }
            if (image.getWidth() > MAX_DIMENSION || image.getHeight() > MAX_DIMENSION) {
                throw new IllegalArgumentException("Kích thước ảnh tối đa là 4096 x 4096 pixel");
            }
        } catch (java.io.IOException exception) {
            throw new IllegalArgumentException("Không thể đọc file ảnh", exception);
        }
    }

    private boolean matchesMagic(String mimeType, byte[] bytes) {
        return switch (mimeType) {
            case "image/png" -> starts(bytes, 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A);
            case "image/jpeg" -> starts(bytes, 0xFF, 0xD8, 0xFF);
            case "image/gif" -> startsAscii(bytes, "GIF87a") || startsAscii(bytes, "GIF89a");
            case "image/webp" -> bytes.length >= 12
                    && startsAscii(bytes, "RIFF")
                    && asciiAt(bytes, 8, "WEBP");
            case "image/avif" -> bytes.length >= 12 && asciiAt(bytes, 4, "ftyp")
                    && (asciiAt(bytes, 8, "avif") || asciiAt(bytes, 8, "avis"));
            default -> false;
        };
    }

    private boolean starts(byte[] bytes, int... expected) {
        if (bytes.length < expected.length) return false;
        for (int index = 0; index < expected.length; index++) {
            if ((bytes[index] & 0xff) != expected[index]) return false;
        }
        return true;
    }

    private boolean startsAscii(byte[] bytes, String expected) {
        return asciiAt(bytes, 0, expected);
    }

    private boolean asciiAt(byte[] bytes, int offset, String expected) {
        if (bytes.length < offset + expected.length()) return false;
        for (int index = 0; index < expected.length(); index++) {
            if (bytes[offset + index] != (byte) expected.charAt(index)) return false;
        }
        return true;
    }

    public record ValidatedImage(String mimeType, byte[] bytes, String dataUri) {
    }
}
