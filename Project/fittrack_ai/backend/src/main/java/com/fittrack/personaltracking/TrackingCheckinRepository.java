package com.fittrack.personaltracking;
import org.springframework.data.jpa.repository.JpaRepository;
import java.time.LocalDate;
import java.util.*;
public interface TrackingCheckinRepository extends JpaRepository<TrackingCheckin,String> {
 List<TrackingCheckin> findByEntryIdInAndDayBetweenOrderByDayAsc(List<String> entries,LocalDate from,LocalDate to);
 List<TrackingCheckin> findByEntryIdAndDayBetweenOrderByDayAsc(String entry,LocalDate from,LocalDate to);
 Optional<TrackingCheckin> findByEntryIdAndDay(String entry,LocalDate day);
}
