package com.fittrack.nutrition.pantry;
import jakarta.validation.constraints.*;
import java.math.BigDecimal;
import java.time.*;
import java.util.List;
public final class PantryDtos {
 private PantryDtos(){}
 public record Create(@NotBlank String foodId,@NotBlank @Size(max=120) String location,
  @NotBlank @Pattern(regexp="SERVING|GRAM|ML") String unit,
  @NotNull @DecimalMin("0.001") @DecimalMax("1000000000") @Digits(integer=10,fraction=3) BigDecimal quantity,
  LocalDate expiresOn,@Size(max=1000) String note,@NotBlank @Size(max=80) String operationId){}
 public record Edit(@NotNull Long version,@NotBlank @Size(max=120) String location,LocalDate expiresOn,@Size(max=1000) String note,boolean active){}
 public record Operate(@NotNull Long version,@NotBlank @Pattern(regexp="ADD|CONSUME|DISCARD|CORRECTION") String type,
  @NotNull @DecimalMin("0") @DecimalMax("1000000000") @Digits(integer=10,fraction=3) BigDecimal amount,
  @Size(max=1000) String note,@NotBlank @Size(max=80) String operationId){}
 public record Batch(String id,long version,String foodId,String foodName,String location,String unit,BigDecimal quantity,LocalDate expiresOn,String note,boolean active){}
 public record Operation(String id,String type,BigDecimal amount,BigDecimal balanceAfter,String note,LocalDateTime createdAt){}
 public record Suggestion(String id,String name,boolean sufficient,List<String> missing){}
}
