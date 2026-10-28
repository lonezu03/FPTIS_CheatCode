package com.fittrack.workoutplan.dto;
import com.fittrack.workout.dto.CreateWorkoutSessionRequest;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import java.time.*;
import java.util.*;
public final class TrainingProgramDtos {
 private TrainingProgramDtos() {}
 public record Week(@Min(1) @Max(12) int number, boolean deload,
    @Min(1) @Max(14) int targetSessions, @Size(max=500) String targetNote) {}
 public record CycleRequest(@NotBlank @Size(max=180) String name, @NotNull LocalDate startDate,
    Long version, @NotNull @Size(min=4,max=12) List<@Valid Week> weeks) {}
 public record CycleResponse(String id,String name,LocalDate startDate,Long version,List<Week> weeks,
    int plannedSessions,int completedSessions,Map<Integer,Long> completedByWeek) {}
 public record AppointmentRequest(@NotBlank String planId,@NotBlank String dayId,
    @NotNull LocalDateTime startAt,@Min(1) @Max(12) Integer repeatWeeks,String cycleId,
    @Min(1) @Max(12) Integer weekNumber) {}
 public record AppointmentResponse(String id,String title,String planId,String cycleId,Integer weekNumber,
    LocalDateTime startAt,Long version,WorkoutPlanDayResponse day,String completedSessionId,LocalDateTime completedAt) {}
 public record Completion(@NotNull @Valid CreateWorkoutSessionRequest session) {}
}
