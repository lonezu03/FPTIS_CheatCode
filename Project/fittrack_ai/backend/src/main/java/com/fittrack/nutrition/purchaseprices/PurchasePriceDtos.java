package com.fittrack.nutrition.purchaseprices;
import jakarta.validation.constraints.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
public final class PurchasePriceDtos {
 private PurchasePriceDtos(){}
 public record Input(Long version,@NotBlank String foodId,
  @NotNull @DecimalMin("0.001") @DecimalMax("1000000000") @Digits(integer=10,fraction=3) BigDecimal amount,
  @NotBlank @Pattern(regexp="SERVING|GRAM|ML") String unit,
  @NotNull @DecimalMin("1") @DecimalMax("9000000000000") @Digits(integer=13,fraction=0) BigDecimal totalPrice,
  @NotNull LocalDate purchasedOn,@Size(max=160) String store,@Size(max=1000) String note,@NotBlank @Size(max=80) String operationId){}
 public record Price(String id,long version,String foodId,String foodName,BigDecimal amount,String unit,BigDecimal totalPrice,BigDecimal unitPrice,String currency,LocalDate purchasedOn,String store,String note,boolean active){}
 public record CostLine(String foodId,String foodName,BigDecimal amount,String unit,BigDecimal estimatedCost,String priceId,LocalDate priceDate,String store,String reason){}
 public record WeekCost(LocalDate week,LocalDate referenceDate,String currency,BigDecimal knownSubtotal,int pricedLines,int totalLines,double coverage,List<CostLine> items){}
}
