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
}
