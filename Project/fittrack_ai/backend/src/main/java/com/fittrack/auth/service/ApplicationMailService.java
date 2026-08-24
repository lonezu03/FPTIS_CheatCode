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
    private final BrevoMailClient brevoMailClient;

    @Value("${app.mail.enabled:false}")
    private boolean enabled;

    @Value("${app.mail.from:}")
    private String from;

    @Value("${app.mail.provider:smtp}")
    private String provider;

    @Value("${app.mail.sender-name:FitTrack}")
    private String senderName;

    @Value("${spring.mail.host:}")
    private String host;

    @Value("${spring.mail.port:587}")
    private int port;

    @Value("${spring.mail.username:}")
    private String username;

    @Value("${spring.mail.password:}")
    private String password;

    @Value("${app.frontend-url:http://localhost:5173}")
    private String frontendUrl;

    public boolean isEnabled() {
        return enabled;
    }

    public boolean isConfigured() {
        if (!enabled || !hasText(from)) {
            return false;
        }
        return switch (normalizedProvider()) {
            case "brevo" -> brevoMailClient.isConfigured();
            case "smtp" -> hasText(host)
                    && hasText(username)
                    && hasText(password);
            default -> false;
        };
    }

    public MailStatus status() {
        String activeProvider = normalizedProvider();
        String message;
        if (!enabled) {
            message = "Dịch vụ email đang tắt (MAIL_ENABLED=false)";
        } else if (!isConfigured()) {
            message = switch (activeProvider) {
                case "brevo" -> "Thiếu BREVO_API_KEY hoặc MAIL_FROM, hoặc BREVO_API_URL không dùng HTTPS";
                case "smtp" -> "Thiếu MAIL_HOST, MAIL_USERNAME, MAIL_PASSWORD hoặc MAIL_FROM";
                default -> "MAIL_PROVIDER không được hỗ trợ; chỉ chấp nhận brevo hoặc smtp";
            };
        } else if ("brevo".equals(activeProvider)) {
            message = "Brevo Email API đã được cấu hình; hãy gửi email thử để kiểm tra sender";
        } else {
            message = "Cấu hình SMTP đã đầy đủ; hãy gửi email thử để kiểm tra đăng nhập SMTP";
        }
        return new MailStatus(
                enabled,
                isConfigured(),
                activeProvider,
                "brevo".equals(activeProvider) ? brevoMailClient.endpointHost() : host,
                "brevo".equals(activeProvider) ? 443 : port,
                maskEmail(from),
                message
        );
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

    public boolean sendPasswordResetOtpEmail(
            String recipient,
            String fullName,
            String otp
    ) {
        return send(
                recipient,
                "Mã OTP đặt lại mật khẩu FitTrack",
                greeting(fullName)
                        + "\n\nMã OTP đặt lại mật khẩu của bạn là:\n\n"
                        + otp
                        + "\n\nMã có hiệu lực trong 10 phút và chỉ dùng được một lần. "
                        + "Nếu không thực hiện yêu cầu này, bạn có thể bỏ qua email."
        );
    }

    public boolean sendNotificationEmail(
            String recipient,
            String fullName,
            String subject,
            String content
    ) {
        return send(recipient, "FitTrack - " + subject, greeting(fullName) + "\n\n" + content);
    }

    public boolean sendLunchMenuEmail(
            String recipient,
            String fullName,
            String subject,
            String content
    ) {
        String lunchUrl = frontendUrl.replaceAll("/+$", "") + "/lunch";
        return send(
                recipient,
                "FitTrack - " + subject,
                greeting(fullName)
                        + "\n\n"
                        + content
                        + "\n\nChọn món tại: "
                        + lunchUrl
        );
    }

    public boolean sendTestEmail(String recipient, String fullName) {
        return send(
                recipient,
                "Kiểm tra cấu hình email FitTrack",
                greeting(fullName)
                        + "\n\nEmail thử đã được gửi thành công từ backend FitTrack."
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
        if (!isConfigured()) {
            boolean brevoConfigured = "brevo".equals(normalizedProvider())
                    && brevoMailClient.isConfigured();
            log.error(
                    "Email configuration is incomplete: provider={}, host={}, port={}, usernamePresent={}, passwordPresent={}, fromPresent={}, brevoConfigured={}",
                    normalizedProvider(),
                    host,
                    port,
                    hasText(username),
                    hasText(password),
                    hasText(from),
                    brevoConfigured
            );
            return false;
        }
        if ("brevo".equals(normalizedProvider())) {
            boolean sent = brevoMailClient.send(
                    from,
                    senderName,
                    recipient,
                    null,
                    subject,
                    body
            );
            if (sent) {
                log.info("Email sent through Brevo to {} with subject '{}'", maskEmail(recipient), subject);
            }
            return sent;
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
            log.info("Email sent through SMTP to {} with subject '{}'", maskEmail(recipient), subject);
            return true;
        } catch (MailException exception) {
            log.error(
                    "Could not send email to {} through {}:{}: {}",
                    maskEmail(recipient),
                    host,
                    port,
                    exception.getMessage(),
                    exception
            );
            return false;
        }
    }

    private String greeting(String fullName) {
        String name = fullName == null || fullName.isBlank()
                ? "bạn"
                : fullName.trim();
        return "Xin chào " + name + ",";
    }

    private boolean hasText(String value) {
        return value != null && !value.isBlank();
    }

    private String normalizedProvider() {
        return provider == null ? "smtp" : provider.trim().toLowerCase();
    }

    public String deliveryFailureMessage() {
        return "brevo".equals(normalizedProvider())
                ? "Brevo không gửi được email. Kiểm tra BREVO_API_KEY và sender đã xác minh"
                : "Không kết nối được SMTP. Render Free chặn các cổng 25, 465 và 587";
    }

    private String maskEmail(String value) {
        if (!hasText(value) || !value.contains("@")) {
            return "";
        }
        int at = value.indexOf('@');
        String local = value.substring(0, at);
        String masked = local.length() <= 2
                ? "**"
                : local.substring(0, 2) + "***";
        return masked + value.substring(at);
    }

    public record MailStatus(
            boolean enabled,
            boolean configured,
            String provider,
            String host,
            int port,
            String maskedSender,
            String message
    ) {
    }
}
