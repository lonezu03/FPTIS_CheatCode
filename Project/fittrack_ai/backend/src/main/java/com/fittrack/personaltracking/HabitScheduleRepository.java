package com.fittrack.personaltracking;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.*;
public interface HabitScheduleRepository extends JpaRepository<HabitSchedule,String> {
 @org.springframework.data.jpa.repository.Query("select h from HabitSchedule h where h.entryId in :ids and h.effectiveFrom<=:to and (h.effectiveFrom>=:from or h.effectiveFrom=(select max(p.effectiveFrom) from HabitSchedule p where p.entryId=h.entryId and p.effectiveFrom<:from)) order by h.effectiveFrom")
 List<HabitSchedule> window(List<String> ids,java.time.LocalDate from,java.time.LocalDate to);
 Optional<HabitSchedule> findFirstByEntryIdAndEffectiveFromLessThanEqualOrderByEffectiveFromDesc(String id,java.time.LocalDate day);
 List<HabitSchedule> findByEntryIdInOrderByEffectiveFromAsc(List<String> ids);
 List<HabitSchedule> findByEntryIdOrderByEffectiveFromAsc(String id);
 Optional<HabitSchedule> findByEntryIdAndEffectiveFrom(String id,java.time.LocalDate day);
}
