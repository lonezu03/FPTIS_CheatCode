package com.fittrack.personalreport;

import com.fittrack.user.entity.User;
import com.fittrack.nutrition.entity.*;
import com.fittrack.nutrition.repository.MealLogRepository;
import com.fittrack.nutrition.service.NutritionDayQualityService;
import com.fittrack.personaltracking.HabitCalendarService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;
import java.math.BigDecimal;
import java.time.*;
import java.util.*;
import java.util.function.Function;
import java.util.stream.Collectors;

@Service @RequiredArgsConstructor
public class PersonalMonthlyReportService {
 private final JdbcTemplate jdbc;
 private final MealLogRepository meals;
 private final NutritionDayQualityService quality;
 private final HabitCalendarService habits;
 public record Training(long sessions,long trainingDays,long workingSets,Double volumeKgReps){}
 public record Nutrition(int qualifyingDays,int partialDays,int unloggedDays,int observedDays,Double coveragePercent,
   Double averageCalories,Double averageProtein,Double averageCarbs,Double averageFat){}
 public record CurrencyTotals(String currencyCode,String income,String expense,String net){}
 public record FocusTotals(String category,long completedSessions,long focusSeconds){}
 public record Report(LocalDate month,LocalDate through,String timezone,Set<String> sections,Training training,
   Nutrition nutrition,Object habits,List<CurrencyTotals> finance,List<FocusTotals> focus,String disclaimer){}

 @Transactional(readOnly=true)
 public Report report(User user,LocalDate requested,Set<String> sections){
  if(!Boolean.TRUE.equals(user.getActive()))throw error(403,"Tài khoản không hoạt động");
  var today=LocalDate.now(ZoneId.of("Asia/Ho_Chi_Minh"));
  if(requested==null||requested.getYear()<2000||requested.isAfter(today))throw error(400,"Chọn tháng từ năm 2000 đến hiện tại");
  LocalDate month=requested.withDayOfMonth(1),end=month.plusMonths(1).minusDays(1);if(end.isAfter(today))end=today;
  if(sections==null||sections.isEmpty()||!Set.of("TRAINING","NUTRITION","HABITS","FINANCE","FOCUS").containsAll(sections))throw error(400,"Chọn ít nhất một nội dung báo cáo hợp lệ");
  // Validate every requested section BEFORE reading any source, never merely hide a forbidden UI block.
  for(String section:sections){boolean flag=switch(section){case "TRAINING"->Boolean.TRUE.equals(user.getFitnessEnabled());case "NUTRITION"->Boolean.TRUE.equals(user.getHealthEnabled());case "FINANCE"->Boolean.TRUE.equals(user.getFinanceEnabled());default->Boolean.TRUE.equals(user.getTodoEnabled());};if(!flag&&!"ADMIN".equals(user.getRole()))throw error(403,"Chưa được cấp quyền cho nội dung: "+section);}
  return new Report(month,end,"Asia/Ho_Chi_Minh",Set.copyOf(sections),sections.contains("TRAINING")?training(user,month,end):null,
    sections.contains("NUTRITION")?nutrition(user,month,end):null,sections.contains("HABITS")?habitSummary(user,month,end):null,
    sections.contains("FINANCE")?finance(user,month,end):null,sections.contains("FOCUS")?focus(user,month,end):null,
    "Dữ liệu chính chủ theo nội dung đã chọn; thiếu nhật ký không phải số 0. Số liệu tập luyện không phải đánh giá y khoa. Không bao gồm nội dung nhật ký riêng hoặc công nợ nhóm.");
 }
 private Training training(User user,LocalDate from,LocalDate to){
  return jdbc.queryForObject("""
   select count(distinct s.id), count(distinct s.session_date), count(w.id), coalesce(sum(w.weight*w.reps),0)
   from workout_sessions s join workout_sets w on w.session_id=s.id
   where s.user_id=? and s.session_date>=? and s.session_date<=? and w.completed=true
     and coalesce(w.set_type,'NORMAL')<>'WARMUP' and w.reps>0 and w.weight>=0
   """,(rs,row)->{double volume=rs.getDouble(4);return new Training(rs.getLong(1),rs.getLong(2),rs.getLong(3),Double.isFinite(volume)?volume:null);},user.getId(),from,to);
 }
 private Nutrition nutrition(User user,LocalDate from,LocalDate to){
  var rows=meals.findByUserAndLogDateBetweenOrderByLogDateAsc(user,from,to);
  var byDate=rows.stream().collect(Collectors.groupingBy(MealLog::getLogDate));var statuses=quality.statuses(user,from,to);
  int complete=0,partial=0,unlogged=0;var validMeals=new ArrayList<MealLog>();
  for(LocalDate day=from;!day.isAfter(to);day=day.plusDays(1)){
   var status=quality.resolve(day,statuses,byDate);
   if(quality.isComplete(status)){complete++;validMeals.addAll(byDate.getOrDefault(day,List.of()));}
   else if(status==NutritionDayStatus.PARTIAL)partial++;else unlogged++;
  }
  int days=(int)java.time.temporal.ChronoUnit.DAYS.between(from,to)+1;
  return new Nutrition(complete,partial,unlogged,days,100.0*complete/days,average(validMeals,complete,MealLog::getTotalCalories),average(validMeals,complete,MealLog::getTotalProtein),average(validMeals,complete,MealLog::getTotalCarbs),average(validMeals,complete,MealLog::getTotalFat));
 }
 private Double average(List<MealLog> values,int days,Function<MealLog,Double> field){if(days==0||values.stream().anyMatch(v->field.apply(v)==null||!Double.isFinite(field.apply(v))))return null;double total=values.stream().map(field).mapToDouble(Double::doubleValue).sum();return Double.isFinite(total)?total/days:null;}
 private HabitCalendarService.MonthSummary habitSummary(User user,LocalDate from,LocalDate to){return habits.monthSummary(user,from,to);}
 private List<CurrencyTotals> finance(User user,LocalDate from,LocalDate to){
  return jdbc.query("""
    select a.currency_code,
      coalesce(sum(case when t.type='INCOME' then t.amount else 0 end),0),
      coalesce(sum(case when t.type='EXPENSE' then t.amount else 0 end),0)
    from finance_transactions t join finance_accounts a on a.id=t.account_id and a.user_id=t.user_id
    where t.user_id=? and t.status='POSTED' and t.type in ('INCOME','EXPENSE') and t.occurred_at>=? and t.occurred_at<?
    group by a.currency_code order by a.currency_code
   """,(rs,row)->{BigDecimal income=rs.getBigDecimal(2),expense=rs.getBigDecimal(3);return new CurrencyTotals(rs.getString(1),income.toPlainString(),expense.toPlainString(),income.subtract(expense).toPlainString());},user.getId(),from.atStartOfDay(),to.plusDays(1).atStartOfDay());
 }
 private List<FocusTotals> focus(User user,LocalDate from,LocalDate to){
  return jdbc.query("""
   select category,count(*),coalesce(sum(accumulated_seconds),0) from focus_sessions
   where owner_id=? and state='COMPLETED' and mode='FOCUS' and ended_at>=? and ended_at<?
   group by category order by category
   """,(rs,row)->new FocusTotals(rs.getString(1),rs.getLong(2),rs.getLong(3)),user.getId(),from.atStartOfDay(),to.plusDays(1).atStartOfDay());
 }
 private static ResponseStatusException error(int code,String message){return new ResponseStatusException(HttpStatus.valueOf(code),message);}
}
