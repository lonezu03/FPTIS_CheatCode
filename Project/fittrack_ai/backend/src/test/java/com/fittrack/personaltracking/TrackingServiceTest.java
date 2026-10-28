package com.fittrack.personaltracking;
import com.fittrack.user.entity.User;
import com.fittrack.user.repository.UserRepository;
import com.fittrack.personaltracking.TrackingDtos.*;
import org.junit.jupiter.api.*;
import org.springframework.web.server.ResponseStatusException;
import java.time.*;
import java.math.BigDecimal;
import java.util.*;
import static org.mockito.Mockito.*;
import static org.junit.jupiter.api.Assertions.*;

class TrackingServiceTest {
 final TrackingRepository entries=mock(TrackingRepository.class);
 final TrackingCheckinRepository checkins=mock(TrackingCheckinRepository.class);
 final GoalPhaseRepository phases=mock(GoalPhaseRepository.class);
 final UserRepository users=mock(UserRepository.class);
 final HabitScheduleRepository schedules=mock(HabitScheduleRepository.class);
 final TrackingService service=new TrackingService(entries,checkins,phases,schedules,users);
 final User user=User.builder().id("owner").role("ADMIN").build();
 TrackingEntry entry;
 @BeforeEach void setup(){entry=new TrackingEntry();entry.setId("e");entry.setOwnerId("owner");entry.setKind("HABIT");entry.setTitle("Đi bộ");entry.setStartDate(LocalDate.of(2020,1,1));entry.setVersion(2L);when(entries.lock("e","owner","HABIT")).thenReturn(Optional.of(entry));when(checkins.save(any())).thenAnswer(i->i.getArgument(0));}
 @Test void adminCannotReadAnotherOwnersRecord(){when(entries.findByIdAndOwnerIdAndKind("other","owner","HABIT")).thenReturn(Optional.empty());assertEquals(404,assertThrows(ResponseStatusException.class,()->service.history(user,"HABIT","other",LocalDate.now(),LocalDate.now())).getStatusCode().value());verifyNoInteractions(checkins);}
 @Test void staleVersionRejected(){var r=new Request("Đổi",null,null,null,null,null,null,null,List.of(),null,null,null,null,null,false,1L,List.of());assertEquals(409,assertThrows(ResponseStatusException.class,()->service.save(user,"HABIT","e",r)).getStatusCode().value());verify(entries,never()).saveAndFlush(any());}
 @Test void repeatedHabitCheckinUpdatesSameRowAndNeverCreatesTodo(){var schedule=new HabitSchedule();schedule.setEffectiveFrom(LocalDate.of(2020,1,1));when(schedules.findFirstByEntryIdAndEffectiveFromLessThanEqualOrderByEffectiveFromDesc("e",LocalDate.of(2024,1,1))).thenReturn(Optional.of(schedule));var existing=new TrackingCheckin();existing.setId("c");when(checkins.findByEntryIdAndDay("e",LocalDate.of(2024,1,1))).thenReturn(Optional.of(existing));var r=service.checkin(user,"HABIT","e",LocalDate.of(2024,1,1),new CheckinRequest("DONE",null,"x",null));assertEquals("c",r.id());verify(checkins).save(existing);}
 @Test void habitHonorsWeekdayAndRejectsFuture(){entry.setWeekdays("2");assertThrows(ResponseStatusException.class,()->service.checkin(user,"HABIT","e",LocalDate.of(2024,1,1),new CheckinRequest("DONE",null,null,null)));entry.setWeekdays("");assertThrows(ResponseStatusException.class,()->service.checkin(user,"HABIT","e",LocalDate.now().plusYears(1),new CheckinRequest("DONE",null,null,null)));verify(checkins,never()).save(any());}
 @Test void goalMissingValueIsNotZero(){entry.setKind("BODY_GOAL");when(entries.lock("e","owner","BODY_GOAL")).thenReturn(Optional.of(entry));assertThrows(ResponseStatusException.class,()->service.checkin(user,"BODY_GOAL","e",LocalDate.of(2024,1,1),new CheckinRequest(null,null,null,null)));}
 @Test void sleepOvernightAcceptedAndOverlapRejected(){when(users.findByIdForUpdate("owner")).thenReturn(Optional.of(user));when(entries.saveAndFlush(any())).thenAnswer(i->i.getArgument(0));var start=LocalDateTime.of(2024,1,1,23,0);var end=start.plusHours(8);var r=new Request("Ngủ",null,null,null,null,null,null,null,null,start,end,null,2,null,false,null,null);var saved=service.save(user,"RECOVERY",null,r);assertEquals(LocalDate.of(2024,1,2),saved.startDate());assertNull(saved.quality());when(entries.overlaps("owner","",start,end)).thenReturn(1L);assertEquals(409,assertThrows(ResponseStatusException.class,()->service.save(user,"RECOVERY",null,r)).getStatusCode().value());}
 @Test void historyBoundedTo366Days(){when(entries.findByIdAndOwnerIdAndKind("e","owner","HABIT")).thenReturn(Optional.of(entry));assertThrows(ResponseStatusException.class,()->service.history(user,"HABIT","e",LocalDate.of(2020,1,1),LocalDate.of(2025,1,1)));}
}
