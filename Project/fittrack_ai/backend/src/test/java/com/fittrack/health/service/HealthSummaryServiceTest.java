package com.fittrack.health.service;

import com.fittrack.bodytracking.repository.BodyMeasurementRepository;
import com.fittrack.nutrition.repository.MealLogRepository;
import com.fittrack.nutrition.repository.WaterLogRepository;
import com.fittrack.nutrition.service.NutritionDayQualityService;
import com.fittrack.user.entity.User;
import com.fittrack.user.service.GoalCalculatorService;
import com.fittrack.workout.repository.WorkoutSessionRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDate;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class HealthSummaryServiceTest {

    @Mock
    private MealLogRepository mealLogRepository;
    @Mock
    private BodyMeasurementRepository bodyMeasurementRepository;
    @Mock
    private WorkoutSessionRepository workoutSessionRepository;
    @Mock
    private NutritionDayQualityService dayQualityService;
    @Mock
    private WaterLogRepository waterLogRepository;

    private HealthSummaryService service;

    @BeforeEach
    void setUp() {
        service = new HealthSummaryService(
                mealLogRepository,
                bodyMeasurementRepository,
                workoutSessionRepository,
                new GoalCalculatorService(),
                dayQualityService,
                waterLogRepository
        );
    }

    @Test
    void emptyHistoryReturnsAUsableSummaryInsteadOfFailing() {
        User user = User.builder()
                .weight(60.0)
                .height(170.0)
                .age(28)
                .gender("MALE")
                .goal("MAINTAIN")
                .activityLevel("LIGHT")
                .build();
        when(mealLogRepository
                .findByUserAndLogDateBetweenOrderByLogDateAsc(
                        any(User.class),
                        any(LocalDate.class),
                        any(LocalDate.class)
                )).thenReturn(List.of());
        when(workoutSessionRepository
                .findByUserAndSessionDateBetweenOrderBySessionDateAsc(
                        any(User.class),
                        any(LocalDate.class),
                        any(LocalDate.class)
                )).thenReturn(List.of());
        when(bodyMeasurementRepository
                .findByUserAndRecordDateBetweenOrderByRecordDateAsc(
                        any(User.class),
                        any(LocalDate.class),
                        any(LocalDate.class)
                )).thenReturn(List.of());
        when(dayQualityService.statuses(any(User.class), any(LocalDate.class), any(LocalDate.class)))
                .thenReturn(java.util.Map.of());
        when(waterLogRepository.findByUserAndLoggedAtBetweenOrderByLoggedAtDesc(
                any(User.class), any(java.time.LocalDateTime.class), any(java.time.LocalDateTime.class)
        )).thenReturn(List.of());

        var summary = assertDoesNotThrow(() -> service.summarize(user, 30));

        assertEquals(30, summary.periodDays());
        assertEquals(0, summary.trackedNutritionDays());
        assertEquals(0, summary.mealCount());
        assertEquals(0, summary.workoutSessions());
        assertEquals(12, summary.nutrients().size());
        assertEquals("NO_DATA", summary.nutrients().stream()
                .filter(metric -> metric.key().equals("water"))
                .findFirst()
                .orElseThrow()
                .status());
        assertEquals(20.8, summary.bmi(), 0.1);
        assertFalse(summary.insights().isEmpty());
    }
}
