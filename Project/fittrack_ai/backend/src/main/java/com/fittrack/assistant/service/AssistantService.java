package com.fittrack.assistant.service;

import com.fittrack.assistant.dto.AssistantDtos.*;
import com.fittrack.assistant.service.GeminiChatClient.AiResult;
import com.fittrack.assistant.service.GeminiChatClient.ToolCall;
import com.fittrack.lunch.dto.LunchDtos.CreateOrderRequest;
import com.fittrack.lunch.service.LunchService;
import com.fittrack.nutrition.dto.CreateMealLogRequest;
import com.fittrack.nutrition.service.NutritionService;
import com.fittrack.user.entity.User;
import com.fittrack.workout.dto.CreateWorkoutSessionRequest;
import com.fittrack.workout.service.WorkoutService;
import jakarta.validation.ConstraintViolation;
import jakarta.validation.Validator;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.Set;
import tools.jackson.core.JacksonException;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;

@Service
@RequiredArgsConstructor
public class AssistantService {

    private final AssistantContextService contextService;
    private final AssistantRateLimiter rateLimiter;
    private final GeminiChatClient geminiClient;
    private final WorkoutService workoutService;
    private final NutritionService nutritionService;
    private final LunchService lunchService;
    private final ObjectMapper objectMapper;
    private final Validator validator;

    public ChatResponse chat(User user, ChatRequest request) {
        int totalCharacters = request.messages()
                .stream()
                .mapToInt(message -> message.content().length())
                .sum();
        if (totalCharacters > 12_000) {
            throw new IllegalArgumentException("Hội thoại quá dài, vui lòng bắt đầu lại");
        }
        if (!rateLimiter.tryAcquire(user.getId())) {
            throw new IllegalArgumentException(
                    "Bạn gửi yêu cầu quá nhanh, vui lòng thử lại sau một phút"
            );
        }
        String context = contextService.buildContext(user);
        AiResult result = geminiClient.respond(request.messages(), context);
        ProposedAction action = toProposedAction(result.toolCall());
        String reply = result.reply();
        if ((reply == null || reply.isBlank()) && action != null) {
            reply = "Tôi đã chuẩn bị thao tác bên dưới. Hãy kiểm tra kỹ rồi xác nhận.";
        }
        return new ChatResponse(reply, action, geminiClient.getModel());
    }

    public ExecuteActionResponse execute(
            User user,
            ExecuteActionRequest request
    ) {
        try {
            return switch (request.type()) {
                case "create_workout_session" -> {
                    CreateWorkoutSessionRequest payload = objectMapper.treeToValue(
                            request.arguments(),
                            CreateWorkoutSessionRequest.class
                    );
                    validate(payload);
                    yield new ExecuteActionResponse(
                            request.type(),
                            "Đã tạo buổi tập",
                            workoutService.createSession(user, payload)
                    );
                }
                case "create_meal_log" -> {
                    CreateMealLogRequest payload = objectMapper.treeToValue(
                            request.arguments(),
                            CreateMealLogRequest.class
                    );
                    validate(payload);
                    yield new ExecuteActionResponse(
                            request.type(),
                            "Đã thêm bữa ăn vào nhật ký",
                            nutritionService.createMealLog(user, payload)
                    );
                }
                case "create_lunch_order" -> {
                    CreateOrderRequest payload = objectMapper.treeToValue(
                            request.arguments(),
                            CreateOrderRequest.class
                    );
                    validate(payload);
                    yield new ExecuteActionResponse(
                            request.type(),
                            "Đã đặt món thành công",
                            lunchService.createOrder(user, payload)
                    );
                }
                default -> throw new IllegalArgumentException(
                        "Thao tác chatbot không được hỗ trợ"
                );
            };
        } catch (JacksonException exception) {
            throw new IllegalArgumentException("Dữ liệu thao tác chatbot không hợp lệ");
        }
    }

    private ProposedAction toProposedAction(ToolCall toolCall) {
        if (toolCall == null) {
            return null;
        }
        if (!Set.of(
                "create_workout_session",
                "create_meal_log",
                "create_lunch_order"
        ).contains(toolCall.name())) {
            throw new IllegalArgumentException("Gemini yêu cầu thao tác không được hỗ trợ");
        }
        return new ProposedAction(
                toolCall.name(),
                toolCall.arguments(),
                actionSummary(toolCall.name(), toolCall.arguments())
        );
    }

    private String actionSummary(String type, JsonNode arguments) {
        return switch (type) {
            case "create_workout_session" ->
                    "Tạo buổi tập ngày " + arguments.path("sessionDate").asText();
            case "create_meal_log" ->
                    "Ghi bữa ăn ngày " + arguments.path("logDate").asText();
            case "create_lunch_order" -> "Đặt món từ thực đơn hôm nay";
            default -> "Thực hiện thao tác";
        };
    }

    private <T> void validate(T payload) {
        Set<ConstraintViolation<T>> violations = validator.validate(payload);
        if (!violations.isEmpty()) {
            ConstraintViolation<T> violation = violations.iterator().next();
            throw new IllegalArgumentException(
                    violation.getPropertyPath() + ": " + violation.getMessage()
            );
        }
    }
}
