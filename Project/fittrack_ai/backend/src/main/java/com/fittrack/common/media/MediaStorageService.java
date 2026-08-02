package com.fittrack.common.media;

import com.fittrack.common.exception.ExternalServiceException;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import tools.jackson.core.JacksonException;
import tools.jackson.databind.ObjectMapper;

import java.io.IOException;
import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.Duration;
import java.time.Instant;
import java.util.Arrays;
import java.util.HexFormat;
import java.util.Set;
import java.util.stream.Collectors;
import java.util.Base64;

@Service
public class MediaStorageService {

    private final ImageValidator validator;
    private final ObjectMapper objectMapper;
    private final HttpClient httpClient;
    private final String provider;
    private final String cloudName;
    private final String apiKey;
    private final String apiSecret;
    private final Set<String> allowedHosts;

    public MediaStorageService(
            ImageValidator validator,
            ObjectMapper objectMapper,
            @Value("${app.media.provider:database}") String provider,
            @Value("${app.media.cloudinary.cloud-name:}") String cloudName,
            @Value("${app.media.cloudinary.api-key:}") String apiKey,
            @Value("${app.media.cloudinary.api-secret:}") String apiSecret,
            @Value("${app.media.allowed-hosts:res.cloudinary.com}") String allowedHosts
    ) {
        this.validator = validator;
        this.objectMapper = objectMapper;
        this.provider = provider.trim().toLowerCase();
        this.cloudName = cloudName.trim();
        this.apiKey = apiKey.trim();
        this.apiSecret = apiSecret.trim();
        this.allowedHosts = Arrays.stream(allowedHosts.split(","))
                .map(String::trim).filter(value -> !value.isBlank()).collect(Collectors.toSet());
        this.httpClient = HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(15)).build();
    }

    public String store(
            String currentValue,
            String requestedValue,
            String currentMediaPath,
            String folder,
            String objectId
    ) {
        if (requestedValue == null || requestedValue.isBlank()) return null;
        String trimmed = requestedValue.trim();
        if (trimmed.equals(currentMediaPath) || trimmed.startsWith(currentMediaPath + "?")) {
            return currentValue;
        }
        if (trimmed.startsWith("data:image/")) {
            ImageValidator.ValidatedImage image = validator.validateDataUri(trimmed);
            return "cloudinary".equals(provider)
                    ? uploadCloudinary(image.dataUri(), folder, objectId)
                    : image.dataUri();
        }
        return validateExternalUrl(trimmed);
    }

    public String storeNew(String requestedValue, String folder, String objectId) {
        return store(null, requestedValue, "", folder, objectId);
    }

    public boolean usesCloudinary() {
        return "cloudinary".equals(provider);
    }

    public DownloadedImage downloadProtected(String value) {
        String url = validateExternalUrl(value);
        HttpRequest request = HttpRequest.newBuilder(URI.create(url))
                .timeout(Duration.ofSeconds(20))
                .GET()
                .build();
        try {
            HttpResponse<byte[]> response = httpClient.send(request, HttpResponse.BodyHandlers.ofByteArray());
            if (response.statusCode() < 200 || response.statusCode() >= 300) {
                throw new ExternalServiceException("Không thể tải ảnh được bảo vệ");
            }
            String contentType = response.headers().firstValue("Content-Type")
                    .map(valueType -> valueType.split(";", 2)[0].trim().toLowerCase())
                    .orElseThrow(() -> new ExternalServiceException("Ảnh không có Content-Type"));
            String dataUri = "data:" + contentType + ";base64," + Base64.getEncoder().encodeToString(response.body());
            ImageValidator.ValidatedImage image = validator.validateDataUri(dataUri);
            return new DownloadedImage(image.mimeType(), image.bytes());
        } catch (InterruptedException exception) {
            Thread.currentThread().interrupt();
            throw new ExternalServiceException("Tải ảnh được bảo vệ bị gián đoạn", exception);
        } catch (IOException exception) {
            throw new ExternalServiceException("Không thể tải ảnh được bảo vệ", exception);
        }
    }

    private String validateExternalUrl(String value) {
        URI uri;
        try {
            uri = URI.create(value);
        } catch (IllegalArgumentException exception) {
            throw new IllegalArgumentException("URL ảnh không hợp lệ", exception);
        }
        if (!"https".equalsIgnoreCase(uri.getScheme())
                || uri.getHost() == null
                || allowedHosts.stream().noneMatch(host ->
                        uri.getHost().equalsIgnoreCase(host)
                                || uri.getHost().toLowerCase().endsWith('.' + host.toLowerCase()))) {
            throw new IllegalArgumentException("URL ảnh phải dùng HTTPS và thuộc máy chủ được cho phép");
        }
        return uri.toString();
    }

    private String uploadCloudinary(String dataUri, String folder, String objectId) {
        ensureCloudinaryConfigured();
        long timestamp = Instant.now().getEpochSecond();
        String publicId = "fittrack/" + folder + '/' + objectId;
        String signed = "overwrite=true&public_id=" + publicId + "&timestamp=" + timestamp;
        String signature = sha1(signed + apiSecret);
        String form = "file=" + encode(dataUri)
                + "&api_key=" + encode(apiKey)
                + "&timestamp=" + timestamp
                + "&public_id=" + encode(publicId)
                + "&overwrite=true"
                + "&signature=" + signature;
        HttpRequest request = HttpRequest.newBuilder(URI.create(
                        "https://api.cloudinary.com/v1_1/" + cloudName + "/image/upload"))
                .timeout(Duration.ofSeconds(60))
                .header("Content-Type", "application/x-www-form-urlencoded")
                .POST(HttpRequest.BodyPublishers.ofString(form))
                .build();
        try {
            HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
            if (response.statusCode() < 200 || response.statusCode() >= 300) {
                throw new ExternalServiceException(
                        "Cloudinary không nhận ảnh (HTTP " + response.statusCode() + ")"
                );
            }
            String secureUrl = objectMapper.readTree(response.body()).path("secure_url").asText("");
            if (secureUrl.isBlank()) throw new ExternalServiceException("Cloudinary không trả về URL ảnh");
            return validateExternalUrl(secureUrl);
        } catch (InterruptedException exception) {
            Thread.currentThread().interrupt();
            throw new ExternalServiceException("Tải ảnh lên Cloudinary bị gián đoạn", exception);
        } catch (IOException | JacksonException exception) {
            throw new ExternalServiceException("Không thể tải ảnh lên Cloudinary", exception);
        }
    }

    private void ensureCloudinaryConfigured() {
        if (cloudName.isBlank() || apiKey.isBlank() || apiSecret.isBlank()) {
            throw new ExternalServiceException(
                    "Cloudinary chưa được cấu hình CLOUDINARY_CLOUD_NAME, CLOUDINARY_API_KEY và CLOUDINARY_API_SECRET"
            );
        }
    }

    private String encode(String value) {
        return URLEncoder.encode(value, StandardCharsets.UTF_8);
    }

    private String sha1(String value) {
        try {
            return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-1")
                    .digest(value.getBytes(StandardCharsets.UTF_8)));
        } catch (NoSuchAlgorithmException exception) {
            throw new IllegalStateException("SHA-1 is unavailable", exception);
        }
    }

    public record DownloadedImage(String mimeType, byte[] bytes) {
    }
}
