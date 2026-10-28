package com.fittrack.personaltracking;

import com.fittrack.user.entity.User;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;
import java.time.*;
import java.time.temporal.ChronoUnit;
import java.util.*;

@Service @RequiredArgsConstructor @Transactional(readOnly=true)
public class HabitCalendarService {
 private final TrackingRepository entries;
 private final TrackingCheckinRepository checkins;
 private final HabitScheduleRepository schedules;
 public record Cell(LocalDate day,String status,boolean scheduled) {}
 public record Calendar(List<Cell> cells,int done,int eligibleDays,int currentStreak,int longestStreak,Double completionRate,boolean historyVerified) {}
 public record MonthSummary(int habitCount,int done,int eligibleDays,Double completionRate,boolean historyVerified){}
 public MonthSummary monthSummary(User user,LocalDate from,LocalDate to){
  if(from==null||to==null||to.isBefore(from)||ChronoUnit.DAYS.between(from,to)>=366)throw new ResponseStatusException(HttpStatus.BAD_REQUEST,"Chọn tối đa 366 ngày");
  var habits=entries.findByOwnerIdAndKind(user.getId(),"HABIT",org.springframework.data.domain.PageRequest.of(0,1001));
  if(habits.size()>1000)throw new ResponseStatusException(HttpStatus.BAD_REQUEST,"Báo cáo hỗ trợ tối đa 1000 thói quen");
  if(habits.isEmpty())return new MonthSummary(0,0,0,null,true);
  var ids=habits.stream().map(TrackingEntry::getId).toList();
  var history=schedules.window(ids,from,to).stream().collect(java.util.stream.Collectors.groupingBy(HabitSchedule::getEntryId));
  var actual=checkins.findByEntryIdInAndDayBetweenOrderByDayAsc(ids,from,to).stream().collect(java.util.stream.Collectors.groupingBy(TrackingCheckin::getEntryId));
  int done=0,eligible=0;boolean verified=true;
  for(var habit:habits){var c=summarize(habit,history.getOrDefault(habit.getId(),List.of()),actual.getOrDefault(habit.getId(),List.of()),from,to,LocalDate.now(ZoneId.of("Asia/Ho_Chi_Minh")));done+=c.done();eligible+=c.eligibleDays();verified&=c.historyVerified();}
  return new MonthSummary(habits.size(),done,eligible,eligible==0?null:100.0*done/eligible,verified);
 }
 public Calendar calendar(User u,String id,LocalDate from,LocalDate to){
  if(from==null||to==null||to.isBefore(from)||ChronoUnit.DAYS.between(from,to)>=366)throw new ResponseStatusException(HttpStatus.BAD_REQUEST,"Chọn tối đa 366 ngày");
  var entry=entries.findByIdAndOwnerIdAndKind(id,u.getId(),"HABIT").orElseThrow(()->new ResponseStatusException(HttpStatus.NOT_FOUND,"Không tìm thấy thói quen của bạn"));
  return summarize(entry,schedules.window(List.of(id),from,to),checkins.findByEntryIdAndDayBetweenOrderByDayAsc(id,from,to),from,to,LocalDate.now(ZoneId.of("Asia/Ho_Chi_Minh")));
 }
 public static Calendar summarize(TrackingEntry entry,List<HabitSchedule> schedules,List<TrackingCheckin> checkins,LocalDate from,LocalDate to,LocalDate today){
  var byDay=new HashMap<LocalDate,String>();checkins.forEach(c->byDay.put(c.getDay(),c.getStatus()));
  var cells=new ArrayList<Cell>();int done=0,eligible=0,streak=0,longest=0;boolean verified=true;
  for(LocalDate day=from;!day.isAfter(to);day=day.plusDays(1)){
   HabitSchedule schedule=null;for(var s:schedules)if(!s.getEffectiveFrom().isAfter(day))schedule=s;
   String status;boolean scheduled=false;
   if(day.isBefore(entry.getStartDate()))status="BEFORE_START";
   else if(entry.getHabitArchivedOn()!=null&&day.isAfter(entry.getHabitArchivedOn()))status="REST";
   else if(day.isAfter(today))status="FUTURE";
   else if(schedule==null){status="UNKNOWN";verified=false;streak=0;}
   else {
    scheduled=scheduled(schedule.getWeekdays(),day);
    if(!scheduled)status="REST";
    else {
     status=byDay.get(day);
     if("DONE".equals(status)){done++;eligible++;streak++;longest=Math.max(longest,streak);}
     else if("SKIPPED".equals(status)){eligible++;streak=0;}
     else if(day.equals(today)){status="PENDING";}
     else {status="MISSED";eligible++;streak=0;}
    }
   }
   cells.add(new Cell(day,status,scheduled));
  }
  return new Calendar(cells,done,eligible,streak,longest,eligible==0?null:100.0*done/eligible,verified);
 }
 static boolean scheduled(String weekdays,LocalDate day){return weekdays==null||weekdays.isBlank()||Arrays.asList(weekdays.split(",")).contains(String.valueOf(day.getDayOfWeek().getValue()));}
}
