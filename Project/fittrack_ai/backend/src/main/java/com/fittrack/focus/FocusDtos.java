package com.fittrack.focus;
import jakarta.validation.constraints.*;
import java.time.LocalDateTime;
public final class FocusDtos {
 private FocusDtos(){}
 public record Start(@NotBlank @Pattern(regexp="[A-Za-z0-9_-]{8,80}")String operationId,
   String todoId,@Size(max=180)String title,@NotBlank @Pattern(regexp="FOCUS|BREAK")String mode,@Min(1)@Max(180)int minutes){}
 public record Command(@NotBlank @Pattern(regexp="[A-Za-z0-9_-]{8,80}")String operationId,@NotNull Long version,
   @NotBlank @Pattern(regexp="PAUSE|RESUME|FINISH|CANCEL")String action){}
 public record View(String id,String todoId,String title,String category,String mode,String state,int plannedSeconds,
   int elapsedSeconds,LocalDateTime createdAt,LocalDateTime runningSince,LocalDateTime endedAt,
   LocalDateTime serverNow,boolean reviewRequired,Long version){}
}
