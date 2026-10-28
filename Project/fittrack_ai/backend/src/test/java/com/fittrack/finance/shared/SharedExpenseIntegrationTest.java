package com.fittrack.finance.shared;

import com.fittrack.FittrackBackendApplication;
import com.fittrack.finance.shared.SharedDtos.*;
import com.fittrack.user.entity.User;
import com.fittrack.user.repository.UserRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.web.server.ResponseStatusException;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.*;
import java.util.concurrent.*;
import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest(classes=FittrackBackendApplication.class) @ActiveProfiles("test")
class SharedExpenseIntegrationTest {
 @Autowired SharedExpenseService service;
 @Autowired UserRepository users;
 @Autowired SharedExpenseRepository expenses;
 @Autowired SharedSettlementRepository settlements;
 @Autowired com.fittrack.finance.repository.FinanceTransactionRepository privateTransactions;
 private String op(){return UUID.randomUUID().toString();}
 private User user(String role){return users.save(User.builder().email(op()+"@example.com").password("encoded").fullName("Thành viên thử").role(role).active(true).financeEnabled(true).build());}
 private String group(User owner){return service.saveGroup(owner,null,new GroupRequest(op(),null,"Nhóm thử",null,false)).id();}
 private long version(User u,String group){return service.detail(u,group).group().version();}
 private void join(User owner,User invited,String id){service.member(owner,id,new MemberRequest(op(),version(owner,id),invited.getEmail(),"INVITE"));var invitation=service.invitations(invited,0,15).content().stream().filter(i->i.groupId().equals(id)).findFirst().orElseThrow();service.member(invited,id,new MemberRequest(op(),invitation.version(),null,"ACCEPT"));}
 private ExpenseRequest expense(User owner,User other,String id,int amount){return new ExpenseRequest(op(),version(owner,id),"Ăn trưa",owner.getId(),BigDecimal.valueOf(amount),LocalDate.now(),"Chỉ sổ nhóm","EQUAL",List.of(new Split(owner.getId(),null),new Split(other.getId(),null)));}
 private BigDecimal balance(User u,String id,String userId){return service.detail(u,id).members().stream().filter(m->m.userId().equals(userId)).findFirst().orElseThrow().balance();}
 @Test void invalidSplitsAreRejectedAndFormerConsentedMembersRemainVisibleAfterReinvite(){
  var a=user("USER");var b=user("USER");var c=user("USER");var id=group(a);join(a,b,id);join(a,c,id);
  var invalid=new ExpenseRequest(op(),version(a,id),"Lỗi",a.getId(),BigDecimal.TEN,LocalDate.now(),null,"EQUAL",java.util.Arrays.asList((Split)null));
  assertEquals(400,assertThrows(ResponseStatusException.class,()->service.preview(a,id,invalid)).getStatusCode().value());assertEquals(400,assertThrows(ResponseStatusException.class,()->service.saveExpense(a,id,null,invalid)).getStatusCode().value());
  var debt=new ExpenseRequest(op(),version(c,id),"C trả cho B",c.getId(),BigDecimal.valueOf(20),LocalDate.now(),null,"CUSTOM",List.of(new Split(b.getId(),BigDecimal.valueOf(20))));service.saveExpense(c,id,null,debt);
  service.member(a,id,new MemberRequest(op(),version(a,id),b.getEmail(),"REMOVE"));service.member(a,id,new MemberRequest(op(),version(a,id),b.getEmail(),"INVITE"));
  assertTrue(service.audit(c,id,0,50).content().stream().noneMatch(entry->entry.detail().contains(b.getEmail())));
  assertEquals(0,balance(c,id,b.getId()).compareTo(BigDecimal.valueOf(-20)));
  var receipt=service.requestSettlement(c,id,new SettlementRequest(op(),version(c,id),b.getId(),c.getId(),BigDecimal.valueOf(20),null));assertNotNull(receipt.id());
 }
 @Test void invitationsRequireConsentAndAdminCannotReadOtherGroups(){
  var owner=user("USER");var invited=user("USER");var admin=user("ADMIN");var id=group(owner);
  service.member(owner,id,new MemberRequest(op(),version(owner,id),invited.getEmail(),"INVITE"));
  assertThrows(ResponseStatusException.class,()->service.detail(invited,id));assertThrows(ResponseStatusException.class,()->service.detail(admin,id));
  assertTrue(service.list(admin,0,15).content().isEmpty());
  var i=service.invitations(invited,0,15).content().getFirst();service.member(invited,id,new MemberRequest(op(),i.version(),null,"ACCEPT"));
  assertEquals(2,service.detail(invited,id).members().size());
  invited.setFinanceEnabled(false);users.save(invited);assertThrows(ResponseStatusException.class,()->service.detail(invited,id));
 }
 @Test void splitPreservesEveryDongWithStableRemainderAndRejectsWrongCustomTotal(){
  var result=SharedExpenseService.equalSplit(BigDecimal.valueOf(100),List.of("c","a","b"));
  assertEquals(List.of(new Split("a",BigDecimal.valueOf(34)),new Split("b",BigDecimal.valueOf(33)),new Split("c",BigDecimal.valueOf(33))),result);
  var a=user("USER");var b=user("USER");var id=group(a);join(a,b,id);var r=expense(a,b,id,101);var preview=service.preview(a,id,r);assertEquals(0,preview.stream().map(Split::amount).reduce(BigDecimal.ZERO,BigDecimal::add).compareTo(BigDecimal.valueOf(101)));
  assertThrows(ResponseStatusException.class,()->service.preview(a,id,new ExpenseRequest(op(),r.version(),r.title(),r.payerId(),BigDecimal.TEN,r.spentOn(),null,"CUSTOM",List.of(new Split(a.getId(),BigDecimal.ONE)))));
  assertThrows(ResponseStatusException.class,()->service.preview(a,id,new ExpenseRequest(op(),r.version(),r.title(),r.payerId(),new BigDecimal("10.2"),r.spentOn(),null,"EQUAL",r.splits())));
 }
 @Test void idempotencyStaleVersionsAndOwnerEditBoundary(){
  var a=user("USER");var b=user("USER");var id=group(a);join(a,b,id);var r=expense(a,b,id,100);var receipt=service.saveExpense(a,id,null,r);assertEquals(receipt,service.saveExpense(a,id,null,r));assertEquals(1,service.expenses(a,id,0,15).totalElements());
  assertThrows(ResponseStatusException.class,()->service.saveExpense(a,id,null,new ExpenseRequest(r.operationId(),r.version(),"Đổi nội dung",r.payerId(),r.amount(),r.spentOn(),null,r.splitMode(),r.splits())));
  assertThrows(ResponseStatusException.class,()->service.saveExpense(a,id,null,new ExpenseRequest(op(),r.version(),r.title(),r.payerId(),r.amount(),r.spentOn(),null,r.splitMode(),r.splits())));
  var e=service.expenses(a,id,0,15).content().getFirst();
  assertThrows(ResponseStatusException.class,()->service.saveExpense(b,id,e.id(),new ExpenseRequest(op(),e.version(),"Không phải khoản của tôi",r.payerId(),r.amount(),r.spentOn(),null,r.splitMode(),r.splits())));
  assertEquals(0,balance(a,id,a.getId()).compareTo(BigDecimal.valueOf(50)));
  assertTrue(service.audit(a,id,0,50).content().stream().anyMatch(x->x.action().equals("CREATE_EXPENSE")));
 }
 @Test void removedMembersKeepDebtAndReadHistoryButCannotAddExpenses(){
  var a=user("USER");var b=user("USER");var id=group(a);join(a,b,id);service.saveExpense(a,id,null,expense(a,b,id,100));service.member(a,id,new MemberRequest(op(),version(a,id),b.getId(),"REMOVE"));
  assertEquals(1,service.expenses(b,id,0,15).totalElements());assertEquals("REMOVED",service.detail(b,id).group().myStatus());assertEquals(0,balance(b,id,b.getId()).compareTo(BigDecimal.valueOf(-50)));
  assertThrows(ResponseStatusException.class,()->service.saveExpense(b,id,null,expense(a,b,id,100)));
  var r=new SettlementRequest(op(),version(b,id),b.getId(),a.getId(),BigDecimal.valueOf(50),null);var s=service.requestSettlement(b,id,r);
  var row=service.settlements(a,id,0,15).content().getFirst();service.resolveSettlement(a,id,s.id(),true,new Mutation(op(),row.version(),null));assertEquals(0,balance(b,id,b.getId()).signum());
 }
 @Test void settlementNeedsCounterpartyConfirmationRechecksDebtAndLocksPaidHistory(){
  var a=user("USER");var b=user("USER");var id=group(a);join(a,b,id);service.saveExpense(a,id,null,expense(a,b,id,100));
  var request=new SettlementRequest(op(),version(a,id),b.getId(),a.getId(),BigDecimal.valueOf(50),"Đã chuyển");var receipt=service.requestSettlement(b,id,request);
  assertEquals(0,balance(a,id,b.getId()).compareTo(BigDecimal.valueOf(-50)));var s=service.settlements(a,id,0,15).content().getFirst();
  assertThrows(ResponseStatusException.class,()->service.resolveSettlement(b,id,receipt.id(),true,new Mutation(op(),s.version(),null)));
  var mutation=new Mutation(op(),s.version(),null);var confirmed=service.resolveSettlement(a,id,s.id(),true,mutation);assertEquals(confirmed,service.resolveSettlement(a,id,s.id(),true,mutation));assertEquals(0,balance(a,id,b.getId()).signum());
  assertThrows(ResponseStatusException.class,()->service.requestSettlement(b,id,new SettlementRequest(op(),version(b,id),b.getId(),a.getId(),BigDecimal.ONE,null)));
  var e=service.expenses(a,id,0,15).content().getFirst();assertThrows(ResponseStatusException.class,()->service.voidExpense(a,id,e.id(),new Mutation(op(),e.version(),"Không được xóa giao dịch đã đối soát")));
 }
 @Test void pendingSettlementCannotOverpayAfterExpenseChangedOrCompetingConfirmation() throws Exception {
  var a=user("USER");var b=user("USER");var id=group(a);join(a,b,id);service.saveExpense(a,id,null,expense(a,b,id,200));
  service.requestSettlement(b,id,new SettlementRequest(op(),version(b,id),b.getId(),a.getId(),BigDecimal.valueOf(100),null));
  service.requestSettlement(b,id,new SettlementRequest(op(),version(b,id),b.getId(),a.getId(),BigDecimal.valueOf(100),null));
  var pending=service.settlements(a,id,0,15).content();var pool=Executors.newFixedThreadPool(2);var start=new CountDownLatch(1);
  try{var futures=pending.stream().map(s->pool.submit(()->{start.await();try{service.resolveSettlement(a,id,s.id(),true,new Mutation(op(),s.version(),null));return true;}catch(ResponseStatusException e){assertEquals(409,e.getStatusCode().value());return false;}})).toList();start.countDown();int successes=0;for(var f:futures)if(f.get(15,TimeUnit.SECONDS))successes++;assertEquals(1,successes);}finally{pool.shutdownNow();}
  assertEquals(0,balance(a,id,b.getId()).signum());
 }
 @Test void pendingPaymentHasNoImpactAndOwnerMayVoidOthersWithAuditReason(){
  var a=user("USER");var b=user("USER");var id=group(a);join(a,b,id);var request=expense(a,b,id,100);var created=service.saveExpense(b,id,null,request);
  var e=service.expenses(a,id,0,15).content().getFirst();
  assertThrows(ResponseStatusException.class,()->service.voidExpense(a,id,created.id(),new Mutation(op(),e.version(),"")));
  service.requestSettlement(b,id,new SettlementRequest(op(),version(b,id),b.getId(),a.getId(),BigDecimal.valueOf(50),null));
  service.voidExpense(a,id,created.id(),new Mutation(op(),e.version(),"Khoản ghi nhầm"));assertEquals(0,balance(a,id,b.getId()).signum());var pending=service.settlements(a,id,0,15).content().getFirst();
  assertThrows(ResponseStatusException.class,()->service.resolveSettlement(a,id,pending.id(),true,new Mutation(op(),pending.version(),null)));
  service.resolveSettlement(a,id,pending.id(),false,new Mutation(op(),pending.version(),"Khoản đã hủy"));assertTrue(service.expenses(a,id,0,15).content().getFirst().voided());
 }
 @Test void archivedGroupReadAndSettlementStillWorkButNewExpenseDoesNot(){
  var a=user("USER");var b=user("USER");var id=group(a);join(a,b,id);service.saveExpense(a,id,null,expense(a,b,id,100));service.saveGroup(a,id,new GroupRequest(op(),version(a,id),"Nhóm lưu",null,true));
  assertThrows(ResponseStatusException.class,()->service.saveExpense(a,id,null,expense(a,b,id,100)));
  assertNotNull(service.requestSettlement(b,id,new SettlementRequest(op(),version(b,id),b.getId(),a.getId(),BigDecimal.valueOf(50),null)));
 }
 @Test void netDebtSupportsChainsWithoutPretendingOriginalPairDebtOrPostingPrivateFinance(){
  long originalCount=privateTransactions.count();var a=user("USER");var b=user("USER");var c=user("USER");var id=group(a);join(a,b,id);join(a,c,id);
  service.saveExpense(a,id,null,new ExpenseRequest(op(),version(a,id),"A trả hộ B",a.getId(),BigDecimal.valueOf(100),LocalDate.now(),null,"CUSTOM",List.of(new Split(b.getId(),BigDecimal.valueOf(100)))));
  service.saveExpense(b,id,null,new ExpenseRequest(op(),version(b,id),"B trả hộ C",b.getId(),BigDecimal.valueOf(100),LocalDate.now(),null,"CUSTOM",List.of(new Split(c.getId(),BigDecimal.valueOf(100)))));
  assertEquals(0,balance(b,id,b.getId()).signum());assertThrows(ResponseStatusException.class,()->service.requestSettlement(c,id,new SettlementRequest(op(),version(c,id),c.getId(),b.getId(),BigDecimal.valueOf(100),null)));
  var receipt=service.requestSettlement(c,id,new SettlementRequest(op(),version(c,id),c.getId(),a.getId(),BigDecimal.valueOf(100),"Bù trừ công nợ ròng"));var row=service.settlements(a,id,0,15).content().getFirst();service.resolveSettlement(a,id,receipt.id(),true,new Mutation(op(),row.version(),null));
  assertTrue(service.detail(a,id).members().stream().allMatch(m->m.balance().signum()==0));assertEquals(originalCount,privateTransactions.count());
 }
}
