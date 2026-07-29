package com.fittrack.common.service;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;

@Service
@ConditionalOnProperty(
        name = "app.keep-alive.enabled",
        havingValue = "true"
)
@Slf4j
public class RenderKeepAliveService {

    private final HttpClient httpClient;
    private final URI healthUri;

    public RenderKeepAliveService(
            @Value("${app.keep-alive.url:}") String serviceUrl
    ) {
        this.httpClient = HttpClient.newBuilder()
                .connectTimeout(Duration.ofSeconds(10))
                .build();
        this.healthUri = serviceUrl == null || serviceUrl.isBlank()
                ? null
                : URI.create(serviceUrl.replaceAll("/+$", "") + "/api/health");
    }

    @Scheduled(
            initialDelayString = "${app.keep-alive.interval-ms:600000}",
            fixedDelayString = "${app.keep-alive.interval-ms:600000}"
    )
    public void ping() {
        if (healthUri == null) {
            log.warn("Keep-alive is enabled but no service URL is configured");
            return;
        }

        HttpRequest request = HttpRequest.newBuilder(healthUri)
                .timeout(Duration.ofSeconds(15))
                .header("User-Agent", "FitTrack-Render-KeepAlive/1.0")
                .GET()
                .build();
        try {
            HttpResponse<Void> response = httpClient.send(
                    request,
                    HttpResponse.BodyHandlers.discarding()
            );
            if (response.statusCode() < 200 || response.statusCode() >= 400) {
                log.warn("Keep-alive returned HTTP {}", response.statusCode());
            }
        } catch (InterruptedException exception) {
            Thread.currentThread().interrupt();
            log.warn("Keep-alive request was interrupted");
        } catch (IOException exception) {
            log.warn("Keep-alive request failed: {}", exception.getMessage());
        }
    }
}
