package com.fittrack.personaltracking;
import com.fittrack.FittrackBackendApplication;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.jdbc.core.JdbcTemplate;
import static org.junit.jupiter.api.Assertions.assertNotNull;
/** H2 schema smoke catches reserved identifiers even when Hibernate logs DDL warnings. */
@SpringBootTest(classes=FittrackBackendApplication.class) @ActiveProfiles("test")
class TrackingSchemaTest {
 @Autowired JdbcTemplate jdbc;
 @Autowired TrackingService service;
 @Autowired com.fittrack.user.repository.UserRepository users;
 @Test void phaseOnlyEditsAdvanceAggregateVersionAndRejectStaleWriter(){
  var user=users.save(com.fittrack.user.entity.User.builder().email(java.util.UUID.randomUUID()+"@example.test").fullName("Phase test").password("encoded").role("USER").build());
  var start=java.time.LocalDate.of(2026,1,1);var end=start.plusMonths(3);
  var r=new TrackingDtos.Request("Tăng sức mạnh",null,"Mức tạ","kg",java.math.BigDecimal.TEN,new java.math.BigDecimal("20"),start,end,null,null,null,null,null,null,false,null,java.util.List.of(new TrackingDtos.Phase("Mốc 1",start.plusMonths(1),new java.math.BigDecimal("15"))));
  var first=service.save(user,"WORKOUT_GOAL",null,r);
  var edit=new TrackingDtos.Request(r.title(),r.note(),r.metric(),r.unit(),r.baseline(),r.target(),r.startDate(),r.targetDate(),null,null,null,null,null,null,false,first.version(),java.util.List.of(new TrackingDtos.Phase("Mốc mới",start.plusMonths(1),new java.math.BigDecimal("16"))));
  var changed=service.save(user,"WORKOUT_GOAL",first.id(),edit);
  org.junit.jupiter.api.Assertions.assertTrue(changed.version()>first.version());
  org.junit.jupiter.api.Assertions.assertThrows(org.springframework.web.server.ResponseStatusException.class,()->service.save(user,"WORKOUT_GOAL",first.id(),edit));
 }
 @Test void allTrackingAndSavingsTablesReallyExist(){
  for(String table:new String[]{"personal_tracking_entries","personal_tracking_checkins","personal_goal_phases","finance_savings_goals","finance_savings_operations"})
   assertNotNull(jdbc.queryForObject("select count(*) from "+table,Long.class));
  jdbc.queryForList("select metric_value,checkin_date from personal_tracking_checkins where 1=0");
 }
 @Test void habitWeekdayEditsStartTomorrowAndPreserveToday(){
  var user=users.save(com.fittrack.user.entity.User.builder().email(java.util.UUID.randomUUID()+"@example.test").fullName("Habit test").password("encoded").role("USER").build());
  var today=java.time.LocalDate.now(java.time.ZoneId.of("Asia/Ho_Chi_Minh"));
  var create=new TrackingDtos.Request("Đi bộ",null,null,null,null,null,today,null,java.util.List.of(),null,null,null,null,null,false,null,null);
  var first=service.save(user,"HABIT",null,create);
  service.checkin(user,"HABIT",first.id(),today,new TrackingDtos.CheckinRequest("DONE",null,null,null));
  var nextWeekday=today.plusDays(1).getDayOfWeek().getValue();
  var edit=new TrackingDtos.Request(first.title(),null,null,null,null,null,today,null,java.util.List.of(nextWeekday),null,null,null,null,null,false,first.version(),null);
  service.save(user,"HABIT",first.id(),edit);
  service.checkin(user,"HABIT",first.id(),today,new TrackingDtos.CheckinRequest("DONE",null,null,null));
  org.junit.jupiter.api.Assertions.assertEquals(2,jdbc.queryForObject("select count(*) from habit_schedule_history where entry_id=?",Integer.class,first.id()));
  org.junit.jupiter.api.Assertions.assertEquals(1,service.history(user,"HABIT",first.id(),today,today).size());
 }
 @Test void futureHabitEditTakesEffectAtStartInsteadOfBeingOverridden(){
  var user=users.save(com.fittrack.user.entity.User.builder().email(java.util.UUID.randomUUID()+"@example.test").fullName("Future habit").password("encoded").role("USER").build());
  var future=java.time.LocalDate.now(java.time.ZoneId.of("Asia/Ho_Chi_Minh")).plusDays(7);
  var first=service.save(user,"HABIT",null,new TrackingDtos.Request("Đi bộ",null,null,null,null,null,future,null,java.util.List.of(1),null,null,null,null,null,false,null,null));
  service.save(user,"HABIT",first.id(),new TrackingDtos.Request(first.title(),null,null,null,null,null,future,null,java.util.List.of(2),null,null,null,null,null,false,first.version(),null));
  org.junit.jupiter.api.Assertions.assertEquals(1,jdbc.queryForObject("select count(*) from habit_schedule_history where entry_id=?",Integer.class,first.id()));
  org.junit.jupiter.api.Assertions.assertEquals("2",jdbc.queryForObject("select weekdays from habit_schedule_history where entry_id=? and effective_from=?",String.class,first.id(),future));
 }
}
