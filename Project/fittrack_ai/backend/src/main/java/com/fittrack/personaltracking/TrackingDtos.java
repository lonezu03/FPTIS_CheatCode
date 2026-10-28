package com.fittrack.personaltracking;
import java.math.BigDecimal;
import java.time.*;
import java.util.List;
public final class TrackingDtos {
 private TrackingDtos(){}
 public record Phase(String title,LocalDate targetDate,BigDecimal target){}
 public record Request(String title,String note,String metric,String unit,BigDecimal baseline,BigDecimal target,
   LocalDate startDate,LocalDate targetDate,List<Integer> weekdays,LocalDateTime sleepStart,LocalDateTime sleepEnd,
   Integer quality,Integer fatigue,Integer soreness,Boolean archived,Long version,List<Phase> phases){}
 public record Response(String id,String kind,String title,String note,String metric,String unit,BigDecimal baseline,BigDecimal target,
   LocalDate startDate,LocalDate targetDate,List<Integer> weekdays,LocalDateTime sleepStart,LocalDateTime sleepEnd,
   Integer quality,Integer fatigue,Integer soreness,boolean archived,Long version,List<Phase> phases){}
 public record CheckinRequest(String status,BigDecimal value,String note,String evidence){}
 public record CheckinResponse(String id,LocalDate day,String status,BigDecimal value,String note,String evidence){}
}
