package com.fittrack.auth.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.MailException;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
@Slf4j
public class ApplicationMailService {

    private final JavaMailSender mailSender;

    @Value("${app.mail.enabled:false}")
    private boolean enabled;

    @Value("${app.mail.from:}")
    private String from;

    @Value("${app.frontend-url:http://localhost:5173}")
    private String frontendUrl;

    public boolean isEnabled() {
        return enabled;
    }

    public boolean sendVerificationEmail(
            String recipient,
            String fullName,
            String rawToken
    ) {
        String link = frontendUrl.replaceAll("/+$", "")
                + "/verify-email?token="
                + rawToken;
        return send(
                recipient,
                "Xác thực tài khoản FitTrack",
                greeting(fullName)
                        + "\n\nVui lòng xác thực email để sử dụng FitTrack:\n"
                        + link
                        + "\n\nLiên kết có hiệu lực trong 30 phút."
        );
    }

    public boolean sendPasswordResetEmail(
            String recipient,
            String fullName,
            String rawToken
    ) {
        String link = frontendUrl.replaceAll("/+$", "")
                + "/reset-password?token="
                + rawToken;
        return send(
                recipient,
                "Đặt lại mật khẩu FitTrack",
                greeting(fullName)
                        + "\n\nBạn vừa yêu cầu đặt lại mật khẩu:\n"
                        + link
                        + "\n\nLiên kết có hiệu lực trong 15 phút. "
                        + "Nếu không thực hiện yêu cầu này, bạn có thể bỏ qua email."
        );
    }

    private boolean send(String recipient, String subject, String body) {
        if (!enabled) {
            log.warn(
                    "Email delivery is disabled; no message was sent to {}",
                    recipient
            );
            return false;
        }
        try {
            SimpleMailMessage message = new SimpleMailMessage();
            if (from != null && !from.isBlank()) {
                message.setFrom(from);
            }
            message.setTo(recipient);
            message.setSubject(subject);
            message.setText(body);
            mailSender.send(message);
            return true;
        } catch (MailException exception) {
            log.error("Could not send authentication email to {}", recipient);
            return false;
        }
    }

    private String greeting(String fullName) {
        String name = fullName == null || fullName.isBlank()
                ? "bạn"
                : fullName.trim();
        return "Xin chào " + name + ",";
    }
}
