package com.fittrack.assistant.service;

import com.fittrack.assistant.dto.AssistantDtos.ChatMessage;
import com.sun.net.httpserver.HttpServer;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import tools.jackson.databind.json.JsonMapper;

import java.io.IOException;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

class OpenAiResponsesClientTest {

    private HttpServer server;
    private String baseUrl;

    @BeforeEach
    void setUp() throws IOException {
        server = HttpServer.create(new InetSocketAddress("127.0.0.1", 0), 0);
        server.createContext("/v1/responses", exchange -> {
            byte[] response = """
                    {
                      "output": [
                        {
                          "type": "message",
                          "content": [
                            {
                              "type": "output_text",
                              "text": "Tôi đã chuẩn bị một buổi tập."
                            }
                          ]
                        },
                        {
                          "type": "function_call",
                          "name": "create_workout_session",
                          "arguments": "{\\"sessionDate\\":\\"2026-07-29\\",\\"note\\":\\"Chân\\",\\"durationMinutes\\":45,\\"sets\\":[]}"
                        }
                      ]
                    }
                    """.getBytes(StandardCharsets.UTF_8);
            exchange.getResponseHeaders().add("Content-Type", "application/json");
            exchange.sendResponseHeaders(200, response.length);
            exchange.getResponseBody().write(response);
            exchange.close();
        });
        server.start();
        baseUrl = "http://127.0.0.1:" + server.getAddress().getPort() + "/v1";
    }

    @AfterEach
    void tearDown() {
        server.stop(0);
    }

    @Test
    void parsesTextAndFunctionCallFromResponsesApi() {
        OpenAiResponsesClient client = new OpenAiResponsesClient(
                JsonMapper.builderWithJackson2Defaults().build(),
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
    }
}
