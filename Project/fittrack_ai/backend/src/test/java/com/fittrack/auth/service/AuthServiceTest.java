package com.fittrack.auth.service;

import com.fittrack.auth.dto.RegisterRequest;
import com.fittrack.common.security.JwtService;
import com.fittrack.user.entity.User;
import com.fittrack.user.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AuthServiceTest {

    @Mock
    private UserRepository userRepository;
    @Mock
    private PasswordEncoder passwordEncoder;
    @Mock
    private JwtService jwtService;
    @Mock
    private AuthTokenService authTokenService;
    @Mock
    private ApplicationMailService mailService;

    private AuthService service;

    @BeforeEach
    void setUp() {
        service = new AuthService(
                userRepository,
                passwordEncoder,
                jwtService,
                authTokenService,
                mailService
        );
    }

    @Test
    void registrationDoesNotBlockLocalLoginWhenMailIsDisabled() {
        RegisterRequest request = request();
        when(userRepository.existsByEmail(request.getEmail())).thenReturn(false);
        when(passwordEncoder.encode(request.getPassword())).thenReturn("encoded");
        when(userRepository.save(any(User.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));
        when(mailService.isEnabled()).thenReturn(false);

        var response = service.register(request);

        assertFalse(response.verificationRequired());
        assertFalse(response.emailSent());
        assertTrue(response.message().contains("đăng nhập ngay"));
        verify(authTokenService, never())
                .createEmailVerificationToken(any(User.class));
        verify(mailService, never())
                .sendVerificationEmail(anyString(), any(), anyString());
        verify(userRepository).save(argThat(User::getEmailVerified));
    }

    @Test
    void registrationRequiresVerificationWhenMailIsEnabled() {
        RegisterRequest request = request();
        when(userRepository.existsByEmail(request.getEmail())).thenReturn(false);
        when(passwordEncoder.encode(request.getPassword())).thenReturn("encoded");
        when(userRepository.save(any(User.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));
        when(mailService.isEnabled()).thenReturn(true);
        when(authTokenService.createEmailVerificationToken(any(User.class)))
                .thenReturn("verification-token");
        when(mailService.sendVerificationEmail(
                request.getEmail(),
                request.getFullName(),
                "verification-token"
        )).thenReturn(true);

        var response = service.register(request);

        assertTrue(response.verificationRequired());
        assertTrue(response.emailSent());
        verify(userRepository).save(argThat(
                user -> !Boolean.TRUE.equals(user.getEmailVerified())
        ));
    }

    private RegisterRequest request() {
        RegisterRequest request = new RegisterRequest();
        request.setEmail("smoke@example.test");
        request.setPassword("Secure123!");
        request.setFullName("Smoke Test");
        return request;
    }
}
