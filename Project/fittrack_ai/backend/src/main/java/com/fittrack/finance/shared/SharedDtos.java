package com.fittrack.finance.shared;
import java.math.BigDecimal;
import java.time.*;
import java.util.List;
public final class SharedDtos {
 private SharedDtos() {}
 public record GroupRequest(String operationId,Long version,String name,String description,Boolean archived) {}
 public record MemberRequest(String operationId,Long version,String email,String action) {}
 public record Mutation(String operationId,Long version,String reason) {}
 public record Split(String userId,BigDecimal amount) {}
 public record ExpenseRequest(String operationId,Long version,String title,String payerId,BigDecimal amount,LocalDate spentOn,String note,String splitMode,List<Split> splits) {}
 public record SettlementRequest(String operationId,Long version,String debtorId,String creditorId,BigDecimal amount,String note) {}
 public record GroupView(String id,String ownerId,String name,String description,boolean archived,Long version,String myStatus) {}
 public record MemberView(String userId,String name,String status,LocalDateTime acceptedAt,BigDecimal balance) {}
 public record GroupDetail(GroupView group,List<MemberView> members,String historyPolicy) {}
 public record Invitation(String groupId,String groupName,String invitedBy,LocalDateTime invitedAt,Long version) {}
 public record ExpenseView(String id,String creatorId,String payerId,String title,BigDecimal amount,LocalDate spentOn,String note,List<Split> splits,boolean voided,Long version) {}
 public record SettlementView(String id,String initiatorId,String debtorId,String creditorId,BigDecimal amount,String status,String note,LocalDateTime createdAt,Long version) {}
 public record AuditView(String id,String actorId,String action,String detail,LocalDateTime createdAt) {}
 public record Receipt(String id,String action) {}
}
