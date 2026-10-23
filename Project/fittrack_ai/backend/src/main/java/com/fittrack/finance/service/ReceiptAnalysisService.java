package com.fittrack.finance.service;

import com.fittrack.assistant.service.AssistantRateLimiter;
import com.fittrack.common.exception.ExternalServiceException;
import com.fittrack.common.exception.TooManyRequestsException;
import com.fittrack.common.media.ImageValidator;
import com.fittrack.finance.dto.ReceiptAnalysisDtos;
import com.fittrack.user.entity.User;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;

import java.math.BigDecimal;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.Base64;
import java.util.List;
import java.util.Map;

@Service
public class ReceiptAnalysisService {
    private final ImageValidator validator;
    private final AssistantRateLimiter limiter;
    private final ObjectMapper mapper;
    private final String apiKey;
    private final URI endpoint;
    private final HttpClient client = HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(15)).build();

    public ReceiptAnalysisService(ImageValidator validator, AssistantRateLimiter limiter, ObjectMapper mapper,
            @Value("${app.gemini.api-key:}") String apiKey,
            @Value("${app.gemini.vision-model:gemini-2.0-flash}") String model,
            @Value("${app.gemini.native-base-url:https://generativelanguage.googleapis.com/v1beta}") String baseUrl) {
        this.validator = validator;
        this.limiter = limiter;
        this.mapper = mapper;
        this.apiKey = apiKey == null ? "" : apiKey.trim();
        this.endpoint = URI.create(baseUrl.replaceAll("/+$", "") + "/models/" + model + ":generateContent");
    }

    public ReceiptAnalysisDtos.Response analyze(User user, ReceiptAnalysisDtos.Request request) {
        if (!limiter.tryAcquire("finance-receipt:" + user.getId())) {
            throw new TooManyRequestsException("Bạn thao tác quá nhanh. Hãy thử lại sau.", 60);
        }
        if (apiKey.isBlank()) throw new ExternalServiceException("Chưa cấu hình GEMINI_API_KEY trên backend");
        var image = validator.validateDataUri(request.imageData());
        String prompt = "Đọc hóa đơn/biên lai trong ảnh. Chỉ trả JSON: {\"amount\":null,\"occurredAt\":null,\"merchant\":null,\"note\":null,\"warning\":null}. amount là tổng tiền thanh toán VND dạng số dương; occurredAt định dạng yyyy-MM-dd'T'HH:mm nếu nhìn rõ, không thì null. Không suy đoán giá trị không thấy rõ. Không trả số thẻ, số tài khoản hay dữ liệu nhạy cảm trong note. Nếu không phải hóa đơn, để các trường null và ghi warning tiếng Việt.";
        Map<String, Object> payload = Map.of("contents", List.of(Map.of("parts", List.of(
                Map.of("text", prompt), Map.of("inline_data", Map.of("mime_type", image.mimeType(),
                        "data", Base64.getEncoder().encodeToString(image.bytes())))))),
                "generationConfig", Map.of("responseMimeType", "application/json", "temperature", 0.1));
        try {
            var httpRequest = HttpRequest.newBuilder(endpoint).timeout(Duration.ofSeconds(60))
                    .header("x-goog-api-key", apiKey).header("Content-Type", "application/json")
                    .POST(HttpRequest.BodyPublishers.ofString(mapper.writeValueAsString(payload))).build();
            var response = client.send(httpRequest, HttpResponse.BodyHandlers.ofString());
            if (response.statusCode() < 200 || response.statusCode() >= 300) {
                throw new ExternalServiceException("Gemini chưa thể đọc hóa đơn (HTTP " + response.statusCode() + ")");
            }
            JsonNode root = mapper.readTree(response.body());
            JsonNode parsed = mapper.readTree(root.path("candidates").path(0).path("content").path("parts").path(0).path("text").asText());
            BigDecimal amount = parsed.path("amount").isNumber() ? parsed.path("amount").decimalValue() : null;
            if (amount != null && amount.signum() <= 0) amount = null;
            return new ReceiptAnalysisDtos.Response(amount, value(parsed, "occurredAt"),
                    safeText(value(parsed, "merchant"), 120), safeText(value(parsed, "note"), 500),
                    safeText(value(parsed, "warning"), 300));
        } catch (ExternalServiceException exception) {
            throw exception;
        } catch (InterruptedException exception) {
            Thread.currentThread().interrupt();
            throw new ExternalServiceException("Đọc hóa đơn đã bị gián đoạn", exception);
        } catch (Exception exception) {
            throw new ExternalServiceException("Không thể đọc hóa đơn", exception);
        }
    }

    private String value(JsonNode node, String field) {
        JsonNode value = node.path(field);
        return value.isString() && !value.asText().isBlank() ? value.asText() : null;
    }

    static String redactFinancialIdentifiers(String value) {
        if (value == null) return null;
        // Redact long digit groups (including spaces/dashes) that could identify a card or bank account.
        return value.replaceAll("(?<![\\d])(?:\\d[ -]?){10,19}(?!\\d)", "[đã ẩn số tài khoản/thẻ]");
    }

    static String safeText(String value, int maxLength) {
        if (value == null) return null;
        String redacted = redactFinancialIdentifiers(value).strip();
        return redacted.length() <= maxLength ? redacted : redacted.substring(0, maxLength);
    }
}
