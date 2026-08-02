package com.fittrack.assistant.controller;

import com.fittrack.assistant.dto.AssistantDtos.ChatRequest;
import com.fittrack.assistant.dto.AssistantDtos.ChatResponse;
import com.fittrack.assistant.dto.AssistantDtos.ExecuteActionRequest;
import com.fittrack.assistant.dto.AssistantDtos.ExecuteActionResponse;
import com.fittrack.assistant.dto.AssistantDtos.PrivacyResponse;
import com.fittrack.assistant.dto.AssistantDtos.UpdatePrivacyRequest;
import com.fittrack.assistant.service.AssistantService;
import com.fittrack.user.entity.User;
import com.fittrack.user.repository.UserRepository;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;

@RestController
@RequestMapping("/api/assistant")
@RequiredArgsConstructor
public class AssistantController {

    private final AssistantService assistantService;
    private final UserRepository userRepository;

    @GetMapping("/privacy")
    public PrivacyResponse privacy(Authentication authentication) {
        return privacyResponse((User) authentication.getPrincipal());
    }

    @PutMapping("/privacy")
    public PrivacyResponse updatePrivacy(
            Authentication authentication,
            @RequestBody UpdatePrivacyRequest request
    ) {
        User user = (User) authentication.getPrincipal();
        user.setAssistantConsent(request.consented());
        user.setAssistantConsentAt(request.consented() ? LocalDateTime.now() : null);
        return privacyResponse(userRepository.save(user));
    }

    @DeleteMapping("/history")
    public void deleteHistory() {
        // The backend deliberately does not persist chat messages. This endpoint
        // makes that retention contract explicit and stays forward compatible.
    }

    @PostMapping("/chat")
    public ChatResponse chat(
            Authentication authentication,
            @Valid @RequestBody ChatRequest request
    ) {
        return assistantService.chat(
                (User) authentication.getPrincipal(),
                request
        );
    }

    @PostMapping("/actions/execute")
    public ExecuteActionResponse execute(
            Authentication authentication,
            @Valid @RequestBody ExecuteActionRequest request
    ) {
        return assistantService.execute(
                (User) authentication.getPrincipal(),
                request
        );
    }

    private PrivacyResponse privacyResponse(User user) {
        return new PrivacyResponse(
                Boolean.TRUE.equals(user.getAssistantConsent()),
                user.getAssistantConsentAt(),
                List.of(
                        "Chỉ số hồ sơ sức khỏe cần cho câu hỏi",
                        "Danh mục món ăn hoặc bài tập khi có liên quan",
                        "Đơn cơm và số dư chỉ khi hỏi về đặt cơm",
                        "Tên đồng nghiệp chỉ khi yêu cầu đặt hoặc trả hộ"
                ),
                "FitTrack không lưu nội dung hội thoại ở backend; trình duyệt chỉ giữ hội thoại đến khi tải lại hoặc người dùng xóa."
        );
    }
}
