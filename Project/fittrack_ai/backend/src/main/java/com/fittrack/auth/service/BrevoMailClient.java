package com.fittrack.auth.service;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import tools.jackson.databind.ObjectMapper;

import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Component
@Slf4j
public class BrevoMailClient {

    private final ObjectMapper objectMapper;
    private final HttpClient httpClient;
    private final String apiKey;
    private final URI sendEmailUri;
    private final Duration requestTimeout;

    public BrevoMailClient(
            ObjectMapper objectMapper,
            @Value("${app.mail.brevo.api-key:}") String apiKey,
            @Value("${app.mail.brevo.api-url:https://api.brevo.com/v3/smtp/email}") String apiUrl,
            @Value("${app.mail.api-connect-timeout-ms:10000}") long connectTimeoutMs,
            @Value("${app.mail.api-read-timeout-ms:15000}") long readTimeoutMs
    ) {
        this.objectMapper = objectMapper;
        this.apiKey = apiKey == null ? "" : apiKey.trim();
        this.sendEmailUri = URI.create(apiUrl);
        this.requestTimeout = Duration.ofMillis(readTimeoutMs);
        this.httpClient = HttpClient.newBuilder()
                .connectTimeout(Duration.ofMillis(connectTimeoutMs))
                .build();
    }

    public boolean isConfigured() {
        return !apiKey.isBlank()
                && isAllowedEndpoint();
    }

    public String endpointHost() {
        return sendEmailUri.getHost();
    }

    public boolean send(
            String from,
            String senderName,
            String recipient,
            String recipientName,
            String subject,
            String body
    ) {
        if (!isConfigured()) {
            log.error("Brevo email API is not configured correctly");
            return false;
        }

        Map<String, String> recipientPayload = new LinkedHashMap<>();
        recipientPayload.put("email", recipient);
        if (recipientName != null && !recipientName.isBlank()) {
            recipientPayload.put("name", recipientName.trim());
        }
        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("sender", Map.of("email", from, "name", senderName));
        payload.put("to", List.of(recipientPayload));
        payload.put("subject", subject);
        payload.put("textContent", body);

        try {
            HttpRequest request = HttpRequest.newBuilder(sendEmailUri)
                    .timeout(requestTimeout)
                    .header("Accept", "application/json")
                    .header("Content-Type", "application/json")
                    .header("api-key", apiKey)
                    .POST(HttpRequest.BodyPublishers.ofString(
                            objectMapper.writeValueAsString(payload)
                    ))
                    .build();
            HttpResponse<String> response = httpClient.send(
                    request,
                    HttpResponse.BodyHandlers.ofString()
            );
            if (response.statusCode() >= 200 && response.statusCode() < 300) {
                return true;
            }
            log.error(
                    "Brevo email API returned HTTP {}: {}",
                    response.statusCode(),
                    abbreviate(response.body(), 800)
            );
            return false;
        } catch (InterruptedException exception) {
            Thread.currentThread().interrupt();
            log.error("Brevo email API request was interrupted", exception);
            return false;
        } catch (IOException | RuntimeException exception) {
            log.error("Could not call Brevo email API: {}", exception.getMessage(), exception);
            return false;
        }
    }

    private String abbreviate(String value, int maxLength) {
        if (value == null || value.length() <= maxLength) {
            return value;
        }
        return value.substring(0, maxLength) + "...";
    }

    private boolean isAllowedEndpoint() {
        if ("https".equalsIgnoreCase(sendEmailUri.getScheme())) {
            return true;
        }
        String host = sendEmailUri.getHost();
        return "http".equalsIgnoreCase(sendEmailUri.getScheme())
                && ("localhost".equalsIgnoreCase(host)
                || "127.0.0.1".equals(host)
                || "::1".equals(host));
    }

}
