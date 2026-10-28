package com.fittrack.personaltracking;
import org.junit.jupiter.api.Test;
import java.time.*;
import java.util.*;
import static org.junit.jupiter.api.Assertions.*;
class HabitCalendarTest {
 private TrackingEntry entry(){var e=new TrackingEntry();e.setStartDate(LocalDate.of(2026,10,19));return e;}
 private HabitSchedule schedule(LocalDate day,String weekdays){var s=new HabitSchedule();s.setEffectiveFrom(day);s.setWeekdays(weekdays);return s;}
 private TrackingCheckin done(LocalDate day){var c=new TrackingCheckin();c.setDay(day);c.setStatus("DONE");return c;}
 @Test void restDoesNotBreakAndTodayIsNotFailure(){var monday=LocalDate.of(2026,10,19);var c=HabitCalendarService.summarize(entry(),List.of(schedule(monday,"1,3,5")),List.of(done(monday),done(monday.plusDays(2))),monday,monday.plusDays(4),monday.plusDays(4));assertEquals(2,c.currentStreak());assertEquals(2,c.eligibleDays());assertEquals("PENDING",c.cells().getLast().status());assertEquals(100,c.completionRate());}
 @Test void skippedBreaksAndHistorySchedulesNotCurrentWeekdays(){var monday=LocalDate.of(2026,10,19);var skip=new TrackingCheckin();skip.setDay(monday.plusDays(2));skip.setStatus("SKIPPED");var c=HabitCalendarService.summarize(entry(),List.of(schedule(monday,"1,3"),schedule(monday.plusDays(3),"4")),List.of(done(monday),skip,done(monday.plusDays(3))),monday,monday.plusDays(4),monday.plusDays(4));assertEquals(1,c.currentStreak());assertEquals(3,c.eligibleDays());assertEquals("REST",c.cells().getLast().status());}
 @Test void legacyUnknownNotTreatedAsMissed(){var monday=LocalDate.of(2026,10,19);var c=HabitCalendarService.summarize(entry(),List.of(schedule(monday.plusDays(3),"")),List.of(),monday,monday.plusDays(3),monday.plusDays(3));assertFalse(c.historyVerified());assertEquals(0,c.eligibleDays());assertNull(c.completionRate());assertEquals("UNKNOWN",c.cells().getFirst().status());}
}
