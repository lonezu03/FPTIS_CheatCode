package com.fittrack.finance.shared;
import com.fittrack.finance.shared.SharedDtos.*;
import com.fittrack.common.dto.PageResponse;
import com.fittrack.user.entity.User;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import java.util.List;
@RestController @RequestMapping("/api/finance/shared") @RequiredArgsConstructor
public class SharedExpenseController {
 private final SharedExpenseService service;
 @GetMapping("/groups") public PageResponse<GroupView> groups(@AuthenticationPrincipal User u,@RequestParam(defaultValue="0")int page,@RequestParam(defaultValue="12")int size){return service.list(u,page,size);}
 @PostMapping("/groups") public Receipt create(@AuthenticationPrincipal User u,@RequestBody GroupRequest r){return service.saveGroup(u,null,r);}
 @PatchMapping("/groups/{id}") public Receipt edit(@AuthenticationPrincipal User u,@PathVariable String id,@RequestBody GroupRequest r){return service.saveGroup(u,id,r);}
 @GetMapping("/invitations") public PageResponse<Invitation> invitations(@AuthenticationPrincipal User u,@RequestParam(defaultValue="0")int page,@RequestParam(defaultValue="12")int size){return service.invitations(u,page,size);}
 @GetMapping("/groups/{id}") public GroupDetail detail(@AuthenticationPrincipal User u,@PathVariable String id){return service.detail(u,id);}
 @PostMapping("/groups/{id}/members") public Receipt member(@AuthenticationPrincipal User u,@PathVariable String id,@RequestBody MemberRequest r){return service.member(u,id,r);}
 @GetMapping("/groups/{id}/expenses") public PageResponse<ExpenseView> expenses(@AuthenticationPrincipal User u,@PathVariable String id,@RequestParam(defaultValue="0")int page,@RequestParam(defaultValue="15")int size){return service.expenses(u,id,page,size);}
 @PostMapping("/groups/{id}/expenses/preview") public List<Split> preview(@AuthenticationPrincipal User u,@PathVariable String id,@RequestBody ExpenseRequest r){return service.preview(u,id,r);}
 @PostMapping("/groups/{id}/expenses") public Receipt expense(@AuthenticationPrincipal User u,@PathVariable String id,@RequestBody ExpenseRequest r){return service.saveExpense(u,id,null,r);}
 @PatchMapping("/groups/{id}/expenses/{expenseId}") public Receipt editExpense(@AuthenticationPrincipal User u,@PathVariable String id,@PathVariable String expenseId,@RequestBody ExpenseRequest r){return service.saveExpense(u,id,expenseId,r);}
 @PostMapping("/groups/{id}/expenses/{expenseId}/void") public Receipt voidExpense(@AuthenticationPrincipal User u,@PathVariable String id,@PathVariable String expenseId,@RequestBody Mutation r){return service.voidExpense(u,id,expenseId,r);}
 @GetMapping("/groups/{id}/settlements") public PageResponse<SettlementView> settlements(@AuthenticationPrincipal User u,@PathVariable String id,@RequestParam(defaultValue="0")int page,@RequestParam(defaultValue="15")int size){return service.settlements(u,id,page,size);}
 @PostMapping("/groups/{id}/settlements") public Receipt request(@AuthenticationPrincipal User u,@PathVariable String id,@RequestBody SettlementRequest r){return service.requestSettlement(u,id,r);}
 @PostMapping("/groups/{id}/settlements/{settlementId}/confirm") public Receipt confirm(@AuthenticationPrincipal User u,@PathVariable String id,@PathVariable String settlementId,@RequestBody Mutation r){return service.resolveSettlement(u,id,settlementId,true,r);}
 @PostMapping("/groups/{id}/settlements/{settlementId}/reject") public Receipt reject(@AuthenticationPrincipal User u,@PathVariable String id,@PathVariable String settlementId,@RequestBody Mutation r){return service.resolveSettlement(u,id,settlementId,false,r);}
 @GetMapping("/groups/{id}/audit") public PageResponse<AuditView> audit(@AuthenticationPrincipal User u,@PathVariable String id,@RequestParam(defaultValue="0")int page,@RequestParam(defaultValue="15")int size){return service.audit(u,id,page,size);}
}
