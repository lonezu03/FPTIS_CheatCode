package com.fittrack.finance.shared;

import com.fittrack.common.dto.PageResponse;
import com.fittrack.finance.shared.SharedDtos.*;
import com.fittrack.user.entity.User;
import com.fittrack.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;
import tools.jackson.databind.ObjectMapper;
import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.*;
import java.util.*;

/** A separate collaborative ledger: never calls private Finance or Lunch ledger services. */
@Service @RequiredArgsConstructor @Transactional
public class SharedExpenseService {
 private final SharedGroupRepository groups;
 private final SharedMemberRepository members;
 private final SharedExpenseRepository expenses;
 private final SharedSettlementRepository settlements;
 private final SharedAuditRepository audits;
 private final UserRepository users;
 private final ObjectMapper json;
 private static final BigDecimal MAX=new BigDecimal("1000000000000");

 @Transactional(readOnly=true) public PageResponse<GroupView> list(User actor,int page,int size){var u=authorized(actor,false);return PageResponse.from(groups.mine(u.getId(),paging(page,size)).map(g->groupView(g,u)));}
 @Transactional(readOnly=true) public PageResponse<Invitation> invitations(User actor,int page,int size){var u=authorized(actor,false);return PageResponse.from(members.findByUserIdAndStatusOrderByInvitedAtDesc(u.getId(),"INVITED",paging(page,size)).map(m->{var g=groups.findById(m.getGroupId()).orElseThrow();return new Invitation(g.getId(),g.getName(),name(g.getOwnerId()),m.getInvitedAt(),g.getVersion());}));}
 @Transactional(readOnly=true) public GroupDetail detail(User actor,String id){var u=authorized(actor,false);var g=readable(u,id);var balances=balances(id);return new GroupDetail(groupView(g,u),members.findByGroupIdOrderByInvitedAtAsc(id).stream().filter(m->!"INVITED".equals(m.getStatus())||m.getAcceptedAt()!=null||u.getId().equals(g.getOwnerId())).map(m->new MemberView(m.getUserId(),m.getDisplayName(),m.getStatus(),m.getAcceptedAt(),balances.getOrDefault(m.getUserId(),BigDecimal.ZERO))).toList(),"Thành viên đã chấp nhận, kể cả đã rời nhóm, được xem toàn bộ lịch sử và công nợ nhóm. Lời mời chưa chấp nhận không có quyền xem. Số dư dương: được nhận; âm: cần trả. Đối soát theo số dư ròng, không chuyển tiền thật.");}
 @Transactional(readOnly=true) public PageResponse<ExpenseView> expenses(User actor,String id,int page,int size){readable(authorized(actor,false),id);return PageResponse.from(expenses.findByGroupIdOrderBySpentOnDescCreatedAtDesc(id,paging(page,size)).map(this::expenseView));}
 @Transactional(readOnly=true) public PageResponse<SettlementView> settlements(User actor,String id,int page,int size){readable(authorized(actor,false),id);return PageResponse.from(settlements.findByGroupIdOrderByCreatedAtDesc(id,paging(page,size)).map(this::settlementView));}
 @Transactional(readOnly=true) public PageResponse<AuditView> audit(User actor,String id,int page,int size){var actorUser=authorized(actor,false);var group=readable(actorUser,id);boolean isOwner=actorUser.getId().equals(group.getOwnerId());return PageResponse.from(audits.findByGroupIdOrderByCreatedAtDesc(id,paging(page,size)).map(a->new AuditView(a.getId(),a.getActorId(),a.getAction(),safeAuditDetail(a,isOwner),a.getCreatedAt())));}

 public Receipt saveGroup(User actor,String id,GroupRequest r){
  var u=authorized(actor,true);String action=id==null?"CREATE_GROUP":"EDIT_GROUP";
  return operation(u,r.operationId(),action,id,r,()->{
   SharedGroup g;
   if(id==null){g=new SharedGroup();g.setOwnerId(u.getId());g.setCreatedAt(now());}
   else {g=locked(id);owner(u,g);version(g.getVersion(),r.version());}
   g.setName(text(r.name(),160,true));g.setDescription(text(r.description(),1000,false));g.setArchived(Boolean.TRUE.equals(r.archived()));groups.saveAndFlush(g);
   if(id==null){var m=new SharedMember();m.setGroupId(g.getId());m.setUserId(u.getId());m.setDisplayName(display(u));m.setStatus("ACTIVE");m.setInvitedAt(now());m.setAcceptedAt(now());members.save(m);}
   bump(g);return new Receipt(g.getId(),action);
  });
 }
 public Receipt member(User actor,String id,MemberRequest r){
  var u=authorized(actor,true);
  return operation(u,r.operationId(),"MEMBER",id,r,()->{
   var g=locked(id);version(g.getVersion(),r.version());String action=Objects.toString(r.action(),"");
   if(Set.of("ACCEPT","DECLINE").contains(action)){
    var m=members.findByGroupIdAndUserId(id,u.getId()).orElseThrow(()->error(404,"Không tìm thấy lời mời"));
    if(!"INVITED".equals(m.getStatus()))throw error(409,"Lời mời không còn chờ xử lý");
    if("ACCEPT".equals(action)){open(g);m.setStatus("ACTIVE");if(m.getAcceptedAt()==null)m.setAcceptedAt(now());}else m.setStatus(m.getAcceptedAt()==null?"DECLINED":"REMOVED");
   }else{
    owner(u,g);open(g);var email=text(r.email(),254,true).toLowerCase(Locale.ROOT);
    var target=("REMOVE".equals(action)?users.findById(email).or(()->users.findByEmail(email)):users.findByEmail(email)).orElseThrow(()->error(400,"Tài khoản không khả dụng"));
    if("INVITE".equals(action)&&!eligible(target))throw error(400,"Tài khoản không khả dụng hoặc chưa có quyền Tài chính");
    if(target.getId().equals(g.getOwnerId()))throw error(400,"Không thay đổi tư cách chủ nhóm");
    var m=members.findByGroupIdAndUserId(id,target.getId()).orElse(null);
    if("INVITE".equals(action)){
     if(m!=null&&Set.of("ACTIVE","INVITED").contains(m.getStatus()))throw error(409,"Thành viên đã tham gia hoặc đã được mời");
     if(m==null){m=new SharedMember();m.setGroupId(id);m.setUserId(target.getId());}
     // Removed members already consented to historical access; reinvitation does not erase that consent.
     m.setStatus("INVITED");m.setDisplayName(display(target));m.setInvitedAt(now());members.save(m);
    }else if("REMOVE".equals(action)){
     if(m==null||!Set.of("ACTIVE","INVITED").contains(m.getStatus()))throw error(404,"Không có thành viên đang tham gia/lời mời");
     m.setStatus(m.getAcceptedAt()==null?"DECLINED":"REMOVED");
    }else throw error(400,"Thao tác thành viên không hợp lệ");
   }
   bump(g);return new Receipt(id,"MEMBER_"+action);
  });
 }
 @Transactional(readOnly=true) public List<Split> preview(User actor,String id,ExpenseRequest r){var u=authorized(actor,false);var g=readable(u,id);active(u,g);return split(id,r);}
 public Receipt saveExpense(User actor,String groupId,String expenseId,ExpenseRequest r){
  var u=authorized(actor,true);return operation(u,r.operationId(),expenseId==null?"CREATE_EXPENSE":"EDIT_EXPENSE",groupId+":"+expenseId,r,()->{
   var g=locked(groupId);active(u,g);open(g);SharedExpense e;
   if(expenseId==null){version(g.getVersion(),r.version());e=new SharedExpense();e.setGroupId(groupId);e.setCreatorId(u.getId());e.setCreatedAt(now());}
   else{e=expense(groupId,expenseId);if(!e.getCreatorId().equals(u.getId()))throw error(403,"Chỉ người tạo được sửa khoản chi");version(e.getVersion(),r.version());if(e.isVoided())throw error(409,"Khoản chi đã hủy");unsettledExpense(e);}
   activeParticipant(groupId,r.payerId());var split=split(groupId,r);
   e.setTitle(text(r.title(),180,true));e.setNote(text(r.note(),1000,false));e.setPayerId(r.payerId());e.setAmount(money(r.amount()));
   if(r.spentOn()==null)throw error(400,"Chọn ngày chi tiêu");e.setSpentOn(r.spentOn());e.setSplits(encode(split));expenses.saveAndFlush(e);bump(g);return new Receipt(e.getId(),expenseId==null?"CREATE_EXPENSE":"EDIT_EXPENSE");
  });
 }
 public Receipt voidExpense(User actor,String groupId,String id,Mutation r){
  var u=authorized(actor,true);return operation(u,r.operationId(),"VOID_EXPENSE",groupId+":"+id,r,()->{
   var g=locked(groupId);active(u,g);var e=expense(groupId,id);version(e.getVersion(),r.version());if(e.isVoided())throw error(409,"Khoản chi đã hủy");
   if(!e.getCreatorId().equals(u.getId())&&!g.getOwnerId().equals(u.getId()))throw error(403,"Không có quyền hủy khoản chi");unsettledExpense(e);text(r.reason(),1000,true);e.setVoided(true);bump(g);return new Receipt(id,"VOID_EXPENSE");
  });
 }
 public Receipt requestSettlement(User actor,String groupId,SettlementRequest r){
  var u=authorized(actor,true);return operation(u,r.operationId(),"REQUEST_SETTLEMENT",groupId,r,()->{
   var g=locked(groupId);readMember(u,g);version(g.getVersion(),r.version());
   party(groupId,r.debtorId());party(groupId,r.creditorId());
   if(Objects.equals(r.debtorId(),r.creditorId())||(!u.getId().equals(r.debtorId())&&!u.getId().equals(r.creditorId())))throw error(403,"Bạn phải là một trong hai bên đối soát");
   var amount=money(r.amount());checkDebt(groupId,r.debtorId(),r.creditorId(),amount);
   var s=new SharedSettlement();s.setGroupId(groupId);s.setInitiatorId(u.getId());s.setDebtorId(r.debtorId());s.setCreditorId(r.creditorId());s.setAmount(amount);s.setNote(text(r.note(),1000,false));s.setStatus("PENDING");s.setCreatedAt(now());settlements.saveAndFlush(s);bump(g);return new Receipt(s.getId(),"REQUEST_SETTLEMENT");
  });
 }
 public Receipt resolveSettlement(User actor,String groupId,String id,boolean confirm,Mutation r){
  var u=authorized(actor,true);return operation(u,r.operationId(),confirm?"CONFIRM_SETTLEMENT":"REJECT_SETTLEMENT",groupId+":"+id,r,()->{
   var g=locked(groupId);readMember(u,g);var s=settlements.findById(id).filter(x->groupId.equals(x.getGroupId())).orElseThrow(()->error(404,"Không có đối soát"));
   if(s.getInitiatorId().equals(u.getId())||(!u.getId().equals(s.getDebtorId())&&!u.getId().equals(s.getCreditorId())))throw error(403,"Chỉ bên còn lại được xác nhận hoặc từ chối");
   version(s.getVersion(),r.version());if(!"PENDING".equals(s.getStatus()))throw error(409,"Đối soát đã được xử lý");
   if(confirm)checkDebt(groupId,s.getDebtorId(),s.getCreditorId(),s.getAmount());
   s.setStatus(confirm?"CONFIRMED":"REJECTED");s.setResolvedAt(now());bump(g);return new Receipt(id,s.getStatus());
  });
 }

 private Receipt operation(User u,String operationId,String action,String scope,Object request,java.util.function.Supplier<Receipt> mutation){
  if(operationId==null||!operationId.matches("[A-Za-z0-9_-]{8,80}"))throw error(400,"Mã thao tác không hợp lệ");
  String digest=digest(action+":"+scope+":"+encode(request));var prior=audits.findByActorIdAndOperationId(u.getId(),operationId);
  if(prior.isPresent()){if(!prior.get().getDigest().equals(digest))throw error(409,"Mã thao tác đã dùng cho nội dung khác");return json.readValue(prior.get().getResult(),Receipt.class);}
  var result=mutation.get();String groupId="CREATE_GROUP".equals(action)?result.id():scope.split(":")[0];
  var audit=new SharedAudit();audit.setActorId(u.getId());audit.setGroupId(groupId);audit.setOperationId(operationId);audit.setDigest(digest);audit.setAction(action);audit.setDetail(encode(request));audit.setResult(encode(result));audit.setCreatedAt(now());audits.saveAndFlush(audit);return result;
 }
 private List<Split> split(String id,ExpenseRequest r){
  // Stored audit retains full accountability, but a group member need not see an invitee's email before consent.
  return validatedSplit(id,r);
 }
 @SuppressWarnings("unchecked") private String safeAuditDetail(SharedAudit audit,boolean owner){
  if(owner||!"MEMBER".equals(audit.getAction()))return audit.getDetail();
  var detail=(Map<String,Object>)json.readValue(audit.getDetail(),Map.class);detail.remove("email");return encode(detail);
 }
 private List<Split> validatedSplit(String id,ExpenseRequest r){
  var amount=money(r.amount());if(r.splits()==null||r.splits().isEmpty()||r.splits().size()>100)throw error(400,"Chọn từ 1 đến 100 người tham gia");
  if(r.splits().stream().anyMatch(s->s==null||s.userId()==null||s.userId().isBlank()))throw error(400,"Người tham gia không hợp lệ");
  var ids=r.splits().stream().map(Split::userId).toList();if(new HashSet<>(ids).size()!=ids.size())throw error(400,"Không lặp người tham gia");ids.forEach(user->activeParticipant(id,user));
  if("EQUAL".equals(r.splitMode()))return equalSplit(amount,ids);
  if(!"CUSTOM".equals(r.splitMode()))throw error(400,"Chọn chia đều hoặc nhập số tiền");
  var sum=BigDecimal.ZERO;for(var s:r.splits()){if(s.amount()==null||s.amount().signum()<0||s.amount().stripTrailingZeros().scale()>0||s.amount().compareTo(MAX)>0)throw error(400,"Phần chia phải là số đồng nguyên không âm");sum=sum.add(s.amount());}
  if(sum.compareTo(amount)!=0)throw error(400,"Tổng phần chia phải bằng chính xác số tiền khoản chi");return r.splits();
 }
 public static List<Split> equalSplit(BigDecimal amount,List<String> ids){var sorted=ids.stream().sorted().toList();var division=amount.divideAndRemainder(BigDecimal.valueOf(sorted.size()));long remainder=division[1].longValueExact();var result=new ArrayList<Split>();for(int i=0;i<sorted.size();i++)result.add(new Split(sorted.get(i),division[0].add(i<remainder?BigDecimal.ONE:BigDecimal.ZERO)));return result;}
 private Map<String,BigDecimal> balances(String id){
  var result=new HashMap<String,BigDecimal>();
  for(var e:expenses.findByGroupIdAndVoidedFalse(id)){result.merge(e.getPayerId(),e.getAmount(),BigDecimal::add);for(var s:decodeSplits(e.getSplits()))result.merge(s.userId(),s.amount().negate(),BigDecimal::add);}
  for(var s:settlements.findByGroupIdAndStatus(id,"CONFIRMED")){result.merge(s.getDebtorId(),s.getAmount(),BigDecimal::add);result.merge(s.getCreditorId(),s.getAmount().negate(),BigDecimal::add);}return result;
 }
 private void checkDebt(String groupId,String debtor,String creditor,BigDecimal amount){var balances=balances(groupId);var available=balances.getOrDefault(debtor,BigDecimal.ZERO).negate().min(balances.getOrDefault(creditor,BigDecimal.ZERO));if(amount.compareTo(available)>0)throw error(409,"Số tiền vượt công nợ ròng hiện tại. Tải lại nhóm trước khi đối soát.");}
 private void unsettledExpense(SharedExpense expense){if(settlements.findByGroupIdAndStatus(expense.getGroupId(),"CONFIRMED").stream().anyMatch(s->s.getResolvedAt()!=null&&!s.getResolvedAt().isBefore(expense.getCreatedAt())))throw error(409,"Khoản chi có trước lần đối soát đã xác nhận nên được khóa để bảo toàn công nợ. Không sửa hoặc hủy lịch sử đã thanh toán.");}
 private User authorized(User actor,boolean lock){if(actor==null)throw error(401,"Cần đăng nhập");var u=(lock?users.findByIdForUpdate(actor.getId()):users.findById(actor.getId())).filter(this::eligible).orElseThrow(()->error(403,"Tài khoản chưa có quyền Tài chính hoặc đã khóa"));return u;}
 private boolean eligible(User u){return Boolean.TRUE.equals(u.getActive())&&u.getDeletedAt()==null&&("ADMIN".equalsIgnoreCase(u.getRole())||Boolean.TRUE.equals(u.getFinanceEnabled()));}
 private SharedGroup readable(User u,String id){var g=groups.findById(id).orElseThrow(()->error(404,"Không tìm thấy nhóm"));readMember(u,g);return g;}
 private void readMember(User u,SharedGroup g){var m=members.findByGroupIdAndUserId(g.getId(),u.getId()).orElseThrow(()->error(404,"Không tìm thấy nhóm của bạn"));if(m.getAcceptedAt()==null||!Set.of("ACTIVE","REMOVED","INVITED").contains(m.getStatus()))throw error(403,"Chưa chấp nhận lời mời nhóm");}
 private void active(User u,SharedGroup g){if(!members.findByGroupIdAndUserId(g.getId(),u.getId()).map(m->"ACTIVE".equals(m.getStatus())).orElse(false))throw error(403,"Cần là thành viên đang tham gia");}
 private void activeParticipant(String id,String user){var m=members.findByGroupIdAndUserId(id,user).orElseThrow(()->error(400,"Người tham gia không thuộc nhóm"));if(!"ACTIVE".equals(m.getStatus())||!users.findById(user).map(this::eligible).orElse(false))throw error(400,"Người tham gia phải đang hoạt động, đã chấp nhận và có quyền Tài chính");}
 private void party(String groupId,String userId){var m=members.findByGroupIdAndUserId(groupId,userId).orElseThrow(()->error(400,"Không phải thành viên"));if(m.getAcceptedAt()==null||!users.findById(userId).map(this::eligible).orElse(false))throw error(400,"Bên đối soát không khả dụng");}
 private SharedGroup locked(String id){return groups.lock(id).orElseThrow(()->error(404,"Không tìm thấy nhóm"));}
 private SharedExpense expense(String groupId,String id){return expenses.findById(id).filter(e->groupId.equals(e.getGroupId())).orElseThrow(()->error(404,"Không có khoản chi trong nhóm"));}
 private void owner(User u,SharedGroup g){if(!u.getId().equals(g.getOwnerId()))throw error(403,"Chỉ chủ nhóm được quản lý nhóm/thành viên");}
 private void open(SharedGroup g){if(g.isArchived())throw error(409,"Nhóm đã lưu trữ; chỉ xem lịch sử và đối soát công nợ");}
 private void version(Long actual,Long expected){if(expected==null||!expected.equals(actual))throw error(409,"Dữ liệu đã thay đổi. Tải lại trước khi thao tác.");}
 private void bump(SharedGroup g){g.setRevision(g.getRevision()+1);groups.saveAndFlush(g);}
 private GroupView groupView(SharedGroup g,User u){return new GroupView(g.getId(),g.getOwnerId(),g.getName(),g.getDescription(),g.isArchived(),g.getVersion(),members.findByGroupIdAndUserId(g.getId(),u.getId()).map(SharedMember::getStatus).orElse("NONE"));}
 private ExpenseView expenseView(SharedExpense e){return new ExpenseView(e.getId(),e.getCreatorId(),e.getPayerId(),e.getTitle(),e.getAmount(),e.getSpentOn(),e.getNote(),decodeSplits(e.getSplits()),e.isVoided(),e.getVersion());}
 private SettlementView settlementView(SharedSettlement s){return new SettlementView(s.getId(),s.getInitiatorId(),s.getDebtorId(),s.getCreditorId(),s.getAmount(),s.getStatus(),s.getNote(),s.getCreatedAt(),s.getVersion());}
 private List<Split> decodeSplits(String value){return Arrays.asList(json.readValue(value,Split[].class));}
 private String encode(Object value){return json.writeValueAsString(value);}
 private String name(String id){return users.findById(id).map(this::display).orElse("Thành viên");}
 private String display(User u){String name=u.getFullName();return name==null||name.isBlank()?"Thành viên":name.substring(0,Math.min(160,name.length()));}
 private static BigDecimal money(BigDecimal amount){if(amount==null||amount.signum()<=0||amount.compareTo(MAX)>0||amount.stripTrailingZeros().scale()>0)throw error(400,"Số tiền phải là đồng nguyên, lớn hơn 0, tối đa 1.000.000.000.000 đ");return amount.setScale(0);}
 private static String text(String value,int max,boolean required){if(value==null||value.isBlank()){if(required)throw error(400,"Vui lòng nhập đủ thông tin");return null;}if(value.length()>max)throw error(400,"Nội dung dài quá giới hạn "+max+" ký tự");return value.trim();}
 private static PageRequest paging(int page,int size){return PageRequest.of(Math.max(0,page),Math.max(1,Math.min(50,size)));}
 private static LocalDateTime now(){return LocalDateTime.now(ZoneId.of("Asia/Ho_Chi_Minh"));}
 private static String digest(String value){try{return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(value.getBytes(StandardCharsets.UTF_8)));}catch(Exception e){throw new IllegalStateException(e);}}
 private static ResponseStatusException error(int status,String message){return new ResponseStatusException(HttpStatus.valueOf(status),message);}
}
