package com.fittrack.assistant.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

import java.util.List;
import tools.jackson.databind.JsonNode;

public final class AssistantDtos {

    private AssistantDtos() {
    }

    public record ChatMessage(
            @NotBlank
            @Pattern(regexp = "user|assistant", message = "role không hợp lệ")
            String role,
            @NotBlank
            @Size(max = 4_000)
            String content
    ) {
    }

    public record ChatRequest(
            @NotEmpty
            @Size(max = 20)
            List<@Valid ChatMessage> messages
    ) {
    }

    public record ProposedAction(
            String type,
            JsonNode arguments,
            String summary
    ) {
    }

    public record ChatResponse(
            String reply,
            ProposedAction proposedAction,
            String model
    ) {
    }

    public record ExecuteActionRequest(
            @NotBlank String type,
            @NotNull JsonNode arguments
    ) {
    }

    public record ExecuteActionResponse(
            String type,
            String message,
            Object result
    ) {
    }
}
