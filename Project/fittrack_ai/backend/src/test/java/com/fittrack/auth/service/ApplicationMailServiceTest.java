package com.fittrack.auth.service;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.test.util.ReflectionTestUtils;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class ApplicationMailServiceTest {

    @Mock
    private JavaMailSender mailSender;

    @Mock
    private BrevoMailClient brevoMailClient;

    private ApplicationMailService service;

    @BeforeEach
    void setUp() {
        service = new ApplicationMailService(mailSender, brevoMailClient);
        set("enabled", true);
        set("from", "sender@example.test");
        set("senderName", "FitTrack");
        set("frontendUrl", "https://datcom-nhalam.vercel.app");
        set("host", "smtp.gmail.com");
        set("port", 587);
        set("username", "sender@example.test");
        set("password", "smtp-secret");
    }

    @Test
    void usesBrevoHttpsProviderWithoutCallingSmtp() {
        set("provider", "brevo");
        when(brevoMailClient.isConfigured()).thenReturn(true);
        when(brevoMailClient.endpointHost()).thenReturn("api.brevo.com");
        when(brevoMailClient.send(
                anyString(),
                anyString(),
                anyString(),
                nullable(String.class),
                anyString(),
                anyString()
        )).thenReturn(true);

        assertTrue(service.sendTestEmail("admin@example.test", "Admin"));
        var status = service.status();

        assertTrue(status.configured());
        assertEquals("brevo", status.provider());
        assertEquals("api.brevo.com", status.host());
        assertEquals(443, status.port());
        verifyNoInteractions(mailSender);
    }

    @Test
    void keepsSmtpProviderForLocalOrPaidDeployments() {
        set("provider", "smtp");

        assertTrue(service.sendTestEmail("admin@example.test", "Admin"));
        assertEquals("smtp", service.status().provider());

        verify(mailSender).send(any(SimpleMailMessage.class));
        verifyNoInteractions(brevoMailClient);
    }

    @Test
    void rejectsUnknownProvider() {
        set("provider", "unknown");

        assertFalse(service.isConfigured());
        assertFalse(service.sendTestEmail("admin@example.test", "Admin"));
        verifyNoInteractions(mailSender, brevoMailClient);
    }

    private void set(String field, Object value) {
        ReflectionTestUtils.setField(service, field, value);
    }
}
