package com.fittrack.recommendation.service;

import com.fittrack.recommendation.entity.WeeklyCheckIn;
import com.fittrack.recommendation.repository.WeeklyCheckInRepository;
import com.fittrack.report.dto.WeeklyReportResponse;
import com.fittrack.report.service.WeeklyReportService;
import com.fittrack.user.entity.User;
import com.fittrack.user.repository.UserRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDate;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class WeeklyCoachServiceTest {
    @Mock WeeklyCheckInRepository repository;
    @Mock WeeklyReportService reportService;
    @Mock UserRepository userRepository;
    @InjectMocks WeeklyCoachService service;

    @Test
    void currentDoesNotProposeChangingTargetsWhenDataIsInsufficient() {
        User user = User.builder().id("user-1").goal("CUT").build();
        LocalDate monday = LocalDate.of(2026, 9, 7);
        when(repository.findByUserAndWeekStart(user, monday)).thenReturn(Optional.empty());
        when(reportService.getWeeklyReport(user, monday, monday.plusDays(6))).thenReturn(
                WeeklyReportResponse.builder()
                        .periodDays(7).completeNutritionDays(2).workoutDays(1)
                        .nutritionDataSufficient(false).nutritionConfidencePercent(28.6)
                        .targetCalories(2100.0).targetProtein(130.0).build()
        );
        when(repository.save(any(WeeklyCheckIn.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));

        var result = service.current(user, monday);

        assertThat(result.dataSufficient()).isFalse();
        assertThat(result.canApply()).isFalse();
        assertThat(result.proposedCalories()).isEqualTo(2100.0);
        assertThat(result.rationale()).contains("Chưa đủ dữ liệu");
    }

    @Test
    void acceptingAProposalUpdatesExplicitUserOverrides() {
        User user = User.builder().id("user-1").build();
        WeeklyCheckIn checkIn = WeeklyCheckIn.builder()
                .id("check-1").user(user).status("PENDING").dataSufficient(true)
                .currentCalories(2100.0).proposedCalories(1950.0)
                .currentProtein(130.0).proposedProtein(135.0)
                .confidencePercent(100.0).completeDays(7).workoutDays(3)
                .rationale("Điều chỉnh có kiểm soát").build();
        when(repository.findByIdAndUser("check-1", user)).thenReturn(Optional.of(checkIn));
        when(repository.save(checkIn)).thenReturn(checkIn);

        var result = service.decide(user, "check-1", "ACCEPT");

        assertThat(result.status()).isEqualTo("ACCEPTED");
        assertThat(user.getCalorieTargetOverride()).isEqualTo(1950.0);
        assertThat(user.getProteinTargetOverride()).isEqualTo(135.0);
        verify(userRepository).save(user);
        verify(repository).save(checkIn);
    }
}
