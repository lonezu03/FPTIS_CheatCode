package com.fittrack.personaltracking;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.domain.*;
import jakarta.persistence.LockModeType;
import java.util.*;
import java.time.LocalDateTime;
public interface TrackingRepository extends JpaRepository<TrackingEntry,String> {
 List<TrackingEntry> findByOwnerIdAndKind(String owner,String kind,Pageable page);
 Page<TrackingEntry> findByOwnerIdAndKindAndArchivedOrderByStartDateDesc(String owner,String kind,boolean archived,Pageable page);
 Optional<TrackingEntry> findByIdAndOwnerIdAndKind(String id,String owner,String kind);
 @Lock(LockModeType.PESSIMISTIC_WRITE) @Query("select e from TrackingEntry e where e.id=:id and e.ownerId=:owner and e.kind=:kind")
 Optional<TrackingEntry> lock(String id,String owner,String kind);
 @Query("select count(e) from TrackingEntry e where e.ownerId=:owner and e.kind='RECOVERY' and e.id<>:exclude and e.sleepStart<:end and e.sleepEnd>:start and e.archived=false")
 long overlaps(String owner,String exclude,LocalDateTime start,LocalDateTime end);
}
