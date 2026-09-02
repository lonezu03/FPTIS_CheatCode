package com.fittrack.lunch.service;

import com.fittrack.auth.service.ApplicationMailService;
import com.fittrack.lunch.entity.LunchMenu;
import com.fittrack.lunch.entity.LunchMenuStatus;
import com.fittrack.lunch.entity.LunchNotification;
import com.fittrack.lunch.mapper.LunchMapper;
import com.fittrack.lunch.repository.LunchNotificationRepository;
import com.fittrack.user.entity.User;
import com.fittrack.user.repository.UserRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.ArgumentCaptor;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class LunchNotificationServiceTest {

    @Mock
    private LunchNotificationRepository notificationRepository;

    @Mock
    private UserRepository userRepository;

    @Mock
    private LunchMapper mapper;

    @Mock
    private ApplicationMailService mailService;

    @InjectMocks
    private LunchNotificationService service;

    @Test
    void doesNotCountOptedOutUsersAsFailedEmailDeliveries() {
        User optedOut = User.builder()
                .id("user-off")
                .email("off@example.com")
                .fullName("User Off")
                .emailNotificationsEnabled(false)
                .build();
        User optedIn = User.builder()
                .id("user-on")
                .email("on@example.com")
                .fullName("User On")
                .emailNotificationsEnabled(true)
                .build();
        LunchMenu menu = LunchMenu.builder()
                .id("menu-1")
                .menuDate(LocalDate.of(2026, 8, 29))
                .vendorName("Quán FitTrack")
                .price(35_000L)
                .cutoffAt(LocalDateTime.of(2026, 8, 29, 10, 30))
                .rawMenuText("Cơm gà\nCơm sườn")
                .status(LunchMenuStatus.OPEN)
                .createdBy(optedIn)
                .build();

        when(userRepository.findByActiveTrue()).thenReturn(List.of(optedOut, optedIn));
        when(mailService.sendLunchMenuEmail(
                eq("on@example.com"), eq("User On"), anyString(), anyString()
        )).thenReturn(true);

        LunchNotificationService.DeliverySummary result = service.broadcastMenuAvailable(menu);

        assertEquals(2, result.recipientCount());
        assertEquals(1, result.emailEligibleCount());
        assertEquals(1, result.emailSentCount());
        assertEquals(0, result.emailFailedCount());
        assertEquals(1, result.emailSkippedCount());
        verify(mailService).sendLunchMenuEmail(
                eq("on@example.com"), eq("User On"), anyString(), anyString()
        );
        verify(mailService, never()).sendLunchMenuEmail(
                eq("off@example.com"), eq("User Off"), anyString(), anyString()
        );
        verify(notificationRepository).saveAll(any());
    }

    @Test
    void sendsFitnessAccessRequestOnlyToActiveAdmins() {
        User requester = User.builder()
                .id("user-requester")
                .email("member@example.com")
                .fullName("Nguyễn Thành Viên")
                .fitnessEnabled(false)
                .build();
        User activeAdmin = User.builder()
                .id("admin-active")
                .email("admin@example.com")
                .fullName("Admin")
                .role("ADMIN")
                .active(true)
                .emailNotificationsEnabled(false)
                .build();
        User inactiveAdmin = User.builder()
                .id("admin-inactive")
                .role("ADMIN")
                .active(false)
                .build();
        when(userRepository.findByRoleIgnoreCase("ADMIN"))
                .thenReturn(List.of(activeAdmin, inactiveAdmin));
        when(notificationRepository.existsByDeduplicationKey(anyString()))
                .thenReturn(false);

        var result = service.requestFitnessAccess(requester);

        assertEquals(1, result.notifiedAdminCount());
        assertFalse(result.alreadyRequested());
        assertFalse(result.alreadyGranted());
        assertTrue(result.adminAvailable());
        ArgumentCaptor<LunchNotification> notification =
                ArgumentCaptor.forClass(LunchNotification.class);
        verify(notificationRepository).save(notification.capture());
        assertEquals(activeAdmin, notification.getValue().getRecipient());
        assertEquals("MODULE_ACCESS_REQUEST", notification.getValue().getType());
        assertEquals("USER_ACCESS_REQUEST", notification.getValue().getReferenceType());
        assertEquals(requester.getId(), notification.getValue().getReferenceId());
        assertTrue(notification.getValue().getMessage().contains(requester.getEmail()));
    }

    @Test
    void doesNotSendTheSameFitnessRequestTwiceInOneDay() {
        User requester = User.builder()
                .id("user-requester")
                .email("member@example.com")
                .fullName("Nguyễn Thành Viên")
                .fitnessEnabled(false)
                .build();
        User admin = User.builder()
                .id("admin-active")
                .role("ADMIN")
                .active(true)
                .build();
        when(userRepository.findByRoleIgnoreCase("ADMIN")).thenReturn(List.of(admin));
        when(notificationRepository.existsByDeduplicationKey(anyString())).thenReturn(true);

        var result = service.requestFitnessAccess(requester);

        assertEquals(0, result.notifiedAdminCount());
        assertTrue(result.alreadyRequested());
        assertFalse(result.alreadyGranted());
        verify(notificationRepository, never()).save(any());
    }
}
