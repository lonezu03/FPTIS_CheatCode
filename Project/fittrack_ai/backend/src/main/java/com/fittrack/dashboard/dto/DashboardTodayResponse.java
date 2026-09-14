package com.fittrack.dashboard.dto;

import lombok.Builder;
import lombok.Getter;

import java.time.LocalDate;
import java.util.List;

@Getter
@Builder
public class DashboardTodayResponse {
    private LocalDate date;
    private Double totalCalories;
    private Double totalProtein;
    private Double totalCarbs;
    private Double totalFat;

    private Double targetCalories;
    private Double targetProtein;
    private Double targetCarbs;
    private Double targetFat;

    private Double caloriesProgressPercent;
    private Double proteinProgressPercent;
    private Double carbsProgressPercent;
    private Double fatProgressPercent;

    private Integer mealCount;
    private Integer workoutCount;

    private boolean lunchEnabled;
    private boolean fitnessEnabled;
    private boolean healthEnabled;
    private boolean todoEnabled;
    private boolean scheduleEnabled;
    private boolean quoteEnabled;
    private String latestWorkoutNote;
    private Double remainingCalories;
    private Double remainingProtein;
    private Integer openTodoCount;
    private Integer scheduleCount;
    private List<DashboardAgendaItemResponse> agenda;
    private String coachInsight;
    private String coachActionPath;
}

