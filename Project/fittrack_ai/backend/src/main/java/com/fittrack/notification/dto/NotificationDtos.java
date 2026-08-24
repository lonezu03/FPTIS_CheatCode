package com.fittrack.notification.dto;

import jakarta.validation.constraints.AssertTrue;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

import java.util.List;

public final class NotificationDtos {

    private NotificationDtos() {
    }

    public record BroadcastRequest(
            @NotBlank(message = "Vui lòng nhập tiêu đề")
            @Size(max = 180, message = "Tiêu đề tối đa 180 ký tự")
            String title,
            @NotBlank(message = "Vui lòng nhập nội dung")
            @Size(max = 800, message = "Nội dung tối đa 800 ký tự")
            String message,
            boolean sendToAll,
            List<String> recipientUserIds
    ) {
        @AssertTrue(message = "Vui lòng chọn ít nhất một người nhận")
        public boolean hasRecipients() {
            return sendToAll
                    || (recipientUserIds != null
                    && !recipientUserIds.isEmpty());
        }
    }

    public record BroadcastResponse(
            String message,
            int recipientCount
    ) {
    }

    public record TestEmailResponse(
            String message,
            String recipient
    ) {
    }
}
