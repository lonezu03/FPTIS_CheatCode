package com.fittrack.nutrition.service;

import com.fittrack.assistant.service.AssistantRateLimiter;
import com.fittrack.common.exception.ExternalServiceException;
import com.fittrack.common.exception.TooManyRequestsException;
import com.fittrack.common.media.ImageValidator;
import com.fittrack.nutrition.dto.FoodPhotoAnalysisDtos.*;
import com.fittrack.user.entity.User;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.ArrayList;
import java.util.Base64;
import java.util.List;
import java.util.Map;

@Service
@Slf4j
public class FoodPhotoAnalysisService {
    private final ImageValidator imageValidator;
    private final AssistantRateLimiter rateLimiter;
    private final ObjectMapper objectMapper;
    private final HttpClient httpClient;
    private final String apiKey;
    private final URI endpoint;

    public FoodPhotoAnalysisService(ImageValidator imageValidator, AssistantRateLimiter rateLimiter,
                                    ObjectMapper objectMapper,
                                    @Value("${app.gemini.api-key:}") String apiKey,
                                    @Value("${app.gemini.vision-model:gemini-2.0-flash}") String model,
                                    @Value("${app.gemini.native-base-url:https://generativelanguage.googleapis.com/v1beta}") String baseUrl) {
        this.imageValidator = imageValidator;
        this.rateLimiter = rateLimiter;
        this.objectMapper = objectMapper;
        this.apiKey = apiKey == null ? "" : apiKey.trim();
        this.endpoint = URI.create(baseUrl.replaceAll("/+$", "") + "/models/" + model + ":generateContent");
        this.httpClient = HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(15)).build();
    }

    public FoodPhotoAnalysisResponse analyze(User user, FoodPhotoAnalysisRequest request) {
        if (!rateLimiter.tryAcquire("food-photo:" + user.getId())) {
            throw new TooManyRequestsException("Bạn thao tác quá nhanh. Vui lòng thử lại sau.", 60);
        }
        if (apiKey.isBlank()) throw new ExternalServiceException("Chưa cấu hình GEMINI_API_KEY trên backend");
        ImageValidator.ValidatedImage image = imageValidator.validateDataUri(request.imageData());
        String prompt = """
                Phân tích món ăn trong ảnh. Chỉ trả về JSON hợp lệ, không markdown, theo dạng:
                {"items":[{"name":"tên tiếng Việt","estimatedGrams":0,"calories":0,"protein":0,"carbs":0,"fat":0}],"note":"ghi chú ngắn"}.
                Đây chỉ là ước tính từ ảnh. Không bịa món không nhìn thấy. Nếu không chắc, nêu rõ trong note.
                """;
        Map<String, Object> payload = Map.of(
                "contents", List.of(Map.of("parts", List.of(
                        Map.of("text", prompt),
                        Map.of("inline_data", Map.of("mime_type", image.mimeType(),
                                "data", Base64.getEncoder().encodeToString(image.bytes())))
                ))),
                "generationConfig", Map.of("responseMimeType", "application/json", "temperature", 0.1)
        );
        try {
            HttpRequest httpRequest = HttpRequest.newBuilder(endpoint).timeout(Duration.ofSeconds(60))
                    .header("x-goog-api-key", apiKey).header("Content-Type", "application/json")
                    .POST(HttpRequest.BodyPublishers.ofString(objectMapper.writeValueAsString(payload))).build();
            HttpResponse<String> response = httpClient.send(httpRequest, HttpResponse.BodyHandlers.ofString());
            if (response.statusCode() < 200 || response.statusCode() >= 300) {
                log.warn("Gemini food photo returned status {}", response.statusCode());
                throw new ExternalServiceException("Gemini chưa thể phân tích ảnh món ăn (HTTP " + response.statusCode() + ")");
            }
            String text = objectMapper.readTree(response.body()).path("candidates").path(0)
                    .path("content").path("parts").path(0).path("text").asText();
            JsonNode json = objectMapper.readTree(text);
            List<EstimatedFoodItem> items = new ArrayList<>();
            for (JsonNode item : json.path("items")) {
                items.add(new EstimatedFoodItem(item.path("name").asText("Món chưa xác định"),
                        number(item, "estimatedGrams"), number(item, "calories"),
                        number(item, "protein"), number(item, "carbs"), number(item, "fat")));
            }
            return new FoodPhotoAnalysisResponse(items, json.path("note").asText(
                    "Kết quả chỉ là ước tính; hãy kiểm tra khẩu phần trước khi lưu."), true);
        } catch (ExternalServiceException exception) {
            throw exception;
        } catch (InterruptedException exception) {
            Thread.currentThread().interrupt();
            throw new ExternalServiceException("Phân tích ảnh đã bị gián đoạn", exception);
        } catch (Exception exception) {
            throw new ExternalServiceException("Không thể phân tích ảnh món ăn", exception);
        }
    }

    private Double number(JsonNode node, String field) {
        JsonNode value = node.path(field);
        return value.isNumber() ? value.asDouble() : null;
    }
}
