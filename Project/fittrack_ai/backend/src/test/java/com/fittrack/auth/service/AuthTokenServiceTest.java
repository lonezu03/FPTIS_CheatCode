package com.fittrack.auth.service;

import com.fittrack.auth.entity.UserAuthToken;
import com.fittrack.auth.repository.UserAuthTokenRepository;
import com.fittrack.user.entity.User;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.time.LocalDateTime;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AuthTokenServiceTest {

    @Mock
    private UserAuthTokenRepository tokenRepository;

    @Mock
    private PasswordEncoder passwordEncoder;

    private AuthTokenService service;

    @BeforeEach
    void setUp() {
        service = new AuthTokenService(tokenRepository, passwordEncoder);
    }

    @Test
    void createsSixDigitOtpAndStoresOnlyItsHash() {
        User user = user();
        when(passwordEncoder.encode(anyString())).thenReturn("otp-hash");

        String otp = service.createPasswordResetOtp(user);

        assertTrue(otp.matches("\\d{6}"));
        ArgumentCaptor<UserAuthToken> captor = ArgumentCaptor.forClass(UserAuthToken.class);
        verify(tokenRepository).save(captor.capture());
        UserAuthToken saved = captor.getValue();
        assertEquals("otp-hash", saved.getTokenHash());
        assertNotEquals(otp, saved.getTokenHash());
        assertEquals(AuthTokenService.PASSWORD_RESET_OTP, saved.getType());
        assertEquals(0, saved.getFailedAttempts());
        assertTrue(saved.getExpiresAt().isAfter(LocalDateTime.now().plusMinutes(9)));
    }

    @Test
    void validOtpChangesPasswordAndRevokesAllSessions() {
        User user = user();
        UserAuthToken token = otpToken(user, 0);
        when(tokenRepository.findFirstByUserAndTypeAndUsedAtIsNullOrderByCreatedAtDesc(
                user,
                AuthTokenService.PASSWORD_RESET_OTP
        )).thenReturn(Optional.of(token));
        when(passwordEncoder.matches("123456", "otp-hash")).thenReturn(true);
        when(passwordEncoder.encode("NewPassword123!")).thenReturn("new-password-hash");

        service.resetPasswordWithOtp(user, "123456", "NewPassword123!");

        assertEquals("new-password-hash", user.getPassword());
        assertFalse(user.getPasswordChangeRequired());
        assertEquals(1L, user.getTokenVersion());
        assertNotNull(token.getUsedAt());
        verify(tokenRepository).deleteByUserAndTypeAndUsedAtIsNull(
                user,
                AuthTokenService.REFRESH
        );
    }

    @Test
    void fifthInvalidAttemptLocksOtp() {
        User user = user();
        UserAuthToken token = otpToken(user, 4);
        when(tokenRepository.findFirstByUserAndTypeAndUsedAtIsNullOrderByCreatedAtDesc(
                user,
                AuthTokenService.PASSWORD_RESET_OTP
        )).thenReturn(Optional.of(token));
        when(passwordEncoder.matches("000000", "otp-hash")).thenReturn(false);

        assertThrows(
                IllegalArgumentException.class,
                () -> service.resetPasswordWithOtp(user, "000000", "NewPassword123!")
        );

        assertEquals(5, token.getFailedAttempts());
        assertNotNull(token.getUsedAt());
        verify(passwordEncoder, never()).encode("NewPassword123!");
    }

    private User user() {
        return User.builder()
                .id("user-1")
                .email("user@example.test")
                .password("old-password-hash")
                .active(true)
                .emailVerified(true)
                .passwordChangeRequired(true)
                .tokenVersion(0L)
                .build();
    }

    private UserAuthToken otpToken(User user, int failedAttempts) {
        return UserAuthToken.builder()
                .user(user)
                .tokenHash("otp-hash")
                .type(AuthTokenService.PASSWORD_RESET_OTP)
                .expiresAt(LocalDateTime.now().plusMinutes(5))
                .failedAttempts(failedAttempts)
                .build();
    }
}
