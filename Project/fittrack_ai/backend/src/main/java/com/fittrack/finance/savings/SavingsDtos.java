package com.fittrack.finance.savings;
import java.math.BigDecimal;
import java.time.*;
public final class SavingsDtos {
 private SavingsDtos(){}
 public record Request(String title,BigDecimal target,String currencyCode,LocalDate targetDate,String note,Boolean archived,Long version){}
 public record Response(String id,String title,BigDecimal target,BigDecimal progress,String currencyCode,LocalDate targetDate,String note,boolean archived,Long version){}
 public record OperationRequest(String operationId,String type,BigDecimal amount,String currencyCode,String note){}
 public record OperationResponse(String id,String operationId,String type,BigDecimal amount,String currencyCode,String note,LocalDateTime createdAt){}
}
