package com.fittrack.finance.shared;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.domain.*;
import jakarta.persistence.LockModeType;
import java.util.*;

interface SharedGroupRepository extends JpaRepository<SharedGroup,String> {
 @Lock(LockModeType.PESSIMISTIC_WRITE) @Query("select g from SharedGroup g where g.id=:id") Optional<SharedGroup> lock(String id);
 @Query("select g from SharedGroup g where exists (select m.id from SharedMember m where m.groupId=g.id and m.userId=:userId and (m.status in ('ACTIVE','REMOVED') or (m.status='INVITED' and m.acceptedAt is not null))) order by g.createdAt desc") Page<SharedGroup> mine(String userId,Pageable pageable);
}
interface SharedMemberRepository extends JpaRepository<SharedMember,String> {
 Optional<SharedMember> findByGroupIdAndUserId(String groupId,String userId);
 List<SharedMember> findByGroupIdOrderByInvitedAtAsc(String groupId);
 Page<SharedMember> findByUserIdAndStatusOrderByInvitedAtDesc(String userId,String status,Pageable pageable);
}
interface SharedExpenseRepository extends JpaRepository<SharedExpense,String> {
 Page<SharedExpense> findByGroupIdOrderBySpentOnDescCreatedAtDesc(String groupId,Pageable pageable);
 List<SharedExpense> findByGroupIdAndVoidedFalse(String groupId);
}
interface SharedSettlementRepository extends JpaRepository<SharedSettlement,String> {
 Page<SharedSettlement> findByGroupIdOrderByCreatedAtDesc(String groupId,Pageable pageable);
 List<SharedSettlement> findByGroupIdAndStatus(String groupId,String status);
}
interface SharedAuditRepository extends JpaRepository<SharedAudit,String> {
 Optional<SharedAudit> findByActorIdAndOperationId(String actorId,String operationId);
 Page<SharedAudit> findByGroupIdOrderByCreatedAtDesc(String groupId,Pageable pageable);
}
