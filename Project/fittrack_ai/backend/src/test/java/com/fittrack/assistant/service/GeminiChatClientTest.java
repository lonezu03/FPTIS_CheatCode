package com.fittrack.assistant.service;

import com.fittrack.assistant.dto.AssistantDtos.ChatMessage;
import com.sun.net.httpserver.HttpServer;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.json.JsonMapper;

import java.io.IOException;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.concurrent.atomic.AtomicReference;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

class GeminiChatClientTest {

    private HttpServer server;
    private String baseUrl;
    private final AtomicReference<String> requestBody = new AtomicReference<>();

    @BeforeEach
    void setUp() throws IOException {
        server = HttpServer.create(new InetSocketAddress("127.0.0.1", 0), 0);
        server.createContext("/v1/chat/completions", exchange -> {
            requestBody.set(
                    new String(
                            exchange.getRequestBody().readAllBytes(),
                            StandardCharsets.UTF_8
                    )
            );
            byte[] response = """
                    {
                      "choices": [
                        {
                          "message": {
                            "role": "assistant",
                            "content": "Tôi đã chuẩn bị một buổi tập.",
                            "tool_calls": [
                              {
                                "type": "function",
                                "function": {
                                  "name": "create_workout_session",
                                  "arguments": "{\\"sessionDate\\":\\"2026-07-29\\",\\"note\\":\\"Chân\\",\\"durationMinutes\\":45,\\"sets\\":[]}"
                                }
                              }
                            ]
                          }
                        }
                      ]
                    }
                    """.getBytes(StandardCharsets.UTF_8);
            exchange.getResponseHeaders().add(
                    "Content-Type",
                    "application/json"
            );
            exchange.sendResponseHeaders(200, response.length);
            exchange.getResponseBody().write(response);
            exchange.close();
        });
        server.start();
        baseUrl = "http://127.0.0.1:"
                + server.getAddress().getPort()
                + "/v1";
    }

    @AfterEach
    void tearDown() {
        server.stop(0);
    }

    @Test
    void parsesTextAndFunctionCallFromGeminiChatCompletionsApi()
            throws Exception {
        JsonMapper jsonMapper = JsonMapper.builderWithJackson2Defaults().build();
        GeminiChatClient client = new GeminiChatClient(
                jsonMapper,
                "test-api-key",
                "test-model",
                baseUrl
        );

        var result = client.respond(
                List.of(new ChatMessage("user", "Tạo buổi tập chân")),
                "{}"
        );

        assertEquals("Tôi đã chuẩn bị một buổi tập.", result.reply());
        assertNotNull(result.toolCall());
        assertEquals("create_workout_session", result.toolCall().name());
        assertEquals(
                "2026-07-29",
                result.toolCall().arguments().path("sessionDate").asText()
        );

        JsonNode sentPayload = jsonMapper.readTree(requestBody.get());
        assertEquals("test-model", sentPayload.path("model").asText());
        assertEquals(
                "system",
                sentPayload.path("messages").path(0).path("role").asText()
        );
        assertTrue(sentPayload.path("tools").path(0).has("function"));
    }
}
