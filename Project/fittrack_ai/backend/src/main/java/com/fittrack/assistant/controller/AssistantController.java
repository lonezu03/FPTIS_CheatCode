package com.fittrack.assistant.controller;

import com.fittrack.assistant.dto.AssistantDtos.ChatRequest;
import com.fittrack.assistant.dto.AssistantDtos.ChatResponse;
import com.fittrack.assistant.dto.AssistantDtos.ExecuteActionRequest;
import com.fittrack.assistant.dto.AssistantDtos.ExecuteActionResponse;
import com.fittrack.assistant.service.AssistantService;
import com.fittrack.user.entity.User;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/assistant")
@RequiredArgsConstructor
public class AssistantController {

    private final AssistantService assistantService;

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
}
