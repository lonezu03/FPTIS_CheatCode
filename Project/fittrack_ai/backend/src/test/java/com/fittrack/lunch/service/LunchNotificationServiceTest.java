package com.fittrack.lunch.service;

import com.fittrack.auth.service.ApplicationMailService;
import com.fittrack.lunch.entity.LunchMenu;
import com.fittrack.lunch.entity.LunchMenuStatus;
import com.fittrack.lunch.mapper.LunchMapper;
import com.fittrack.lunch.repository.LunchNotificationRepository;
import com.fittrack.user.entity.User;
import com.fittrack.user.repository.UserRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
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
}
