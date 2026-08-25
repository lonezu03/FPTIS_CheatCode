package com.fittrack.auth.controller;

import com.fittrack.auth.dto.AuthResponse;
import com.fittrack.auth.dto.LoginRequest;
import com.fittrack.auth.service.ApplicationMailService;
import com.fittrack.auth.service.AuthCookieService;
import com.fittrack.auth.service.AuthRateLimitService;
import com.fittrack.auth.service.AuthService;
import com.fittrack.auth.service.AuthTokenService;
import com.fittrack.user.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class AuthControllerTest {

    @Mock
    private AuthService authService;
    @Mock
    private AuthTokenService authTokenService;
    @Mock
    private ApplicationMailService mailService;
    @Mock
    private UserRepository userRepository;
    @Mock
    private AuthCookieService cookieService;
    @Mock
    private AuthRateLimitService rateLimitService;

    private AuthController controller;
    private LoginRequest loginRequest;
    private AuthService.AuthSession session;

    @BeforeEach
    void setUp() {
        controller = new AuthController(
                authService,
                authTokenService,
                mailService,
                userRepository,
                cookieService,
                rateLimitService
        );
        loginRequest = new LoginRequest();
        loginRequest.setEmail("mobile@example.test");
        loginRequest.setPassword("Secure123!");
        session = new AuthService.AuthSession(
                AuthResponse.builder()
                        .token("access-token")
                        .userId("user-1")
                        .email("mobile@example.test")
                        .lunchEnabled(true)
                        .fitnessEnabled(false)
                        .healthEnabled(false)
                        .chatbotEnabled(false)
                        .build(),
                "refresh-token"
        );
        when(authService.login(loginRequest)).thenReturn(session);
    }

    @Test
    void mobileLoginReturnsRefreshTokenInResponseBody() {
        MockHttpServletRequest request = new MockHttpServletRequest();
        request.addHeader("X-FitTrack-Client", "mobile");

        AuthResponse response = controller.login(
                loginRequest,
                request,
                new MockHttpServletResponse()
        );

        assertEquals("refresh-token", response.getRefreshToken());
        assertEquals("access-token", response.getToken());
    }

    @Test
    void webLoginKeepsRefreshTokenOutOfResponseBody() {
        AuthResponse response = controller.login(
                loginRequest,
                new MockHttpServletRequest(),
                new MockHttpServletResponse()
        );

        assertNull(response.getRefreshToken());
    }
}
