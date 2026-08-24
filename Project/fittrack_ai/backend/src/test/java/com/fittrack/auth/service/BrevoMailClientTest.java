package com.fittrack.auth.service;

import com.sun.net.httpserver.HttpServer;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.json.JsonMapper;

import java.io.IOException;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.util.concurrent.atomic.AtomicReference;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

class BrevoMailClientTest {

    private HttpServer server;
    private String apiUrl;
    private final AtomicReference<String> apiKeyHeader = new AtomicReference<>();
    private final AtomicReference<String> requestBody = new AtomicReference<>();

    @BeforeEach
    void setUp() throws IOException {
        server = HttpServer.create(new InetSocketAddress("127.0.0.1", 0), 0);
        server.createContext("/v3/smtp/email", exchange -> {
            apiKeyHeader.set(exchange.getRequestHeaders().getFirst("api-key"));
            requestBody.set(new String(
                    exchange.getRequestBody().readAllBytes(),
                    StandardCharsets.UTF_8
            ));
            byte[] response = "{\"messageId\":\"test-message-id\"}"
                    .getBytes(StandardCharsets.UTF_8);
            exchange.getResponseHeaders().add("Content-Type", "application/json");
            exchange.sendResponseHeaders(201, response.length);
            exchange.getResponseBody().write(response);
            exchange.close();
        });
        server.start();
        apiUrl = "http://127.0.0.1:"
                + server.getAddress().getPort()
                + "/v3/smtp/email";
    }

    @AfterEach
    void tearDown() {
        server.stop(0);
    }

    @Test
    void sendsExpectedTransactionalEmailPayloadOverHttpApi() throws Exception {
        JsonMapper jsonMapper = JsonMapper.builderWithJackson2Defaults().build();
        BrevoMailClient client = new BrevoMailClient(
                jsonMapper,
                "brevo-test-key",
                apiUrl,
                2_000,
                2_000
        );

        assertTrue(client.send(
                "sender@example.test",
                "FitTrack",
                "recipient@example.test",
                "Người dùng",
                "Mã OTP",
                "Mã của bạn là 123456"
        ));
        assertEquals("brevo-test-key", apiKeyHeader.get());

        JsonNode payload = jsonMapper.readTree(requestBody.get());
        assertEquals("sender@example.test", payload.path("sender").path("email").asText());
        assertEquals("FitTrack", payload.path("sender").path("name").asText());
        assertEquals("recipient@example.test", payload.path("to").path(0).path("email").asText());
        assertEquals("Mã OTP", payload.path("subject").asText());
        assertEquals("Mã của bạn là 123456", payload.path("textContent").asText());
    }
}
