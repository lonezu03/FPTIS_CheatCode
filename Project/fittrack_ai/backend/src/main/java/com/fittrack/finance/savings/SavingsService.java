package com.fittrack.finance.savings;
import com.fittrack.finance.savings.SavingsDtos.*;
import com.fittrack.user.entity.User;
import com.fittrack.common.dto.PageResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;
import java.util.*;
import java.math.BigDecimal;
import java.time.*;
@Service @RequiredArgsConstructor @Transactional
public class SavingsService {
 private final SavingsGoalRepository goals;
 private final SavingsOperationRepository operations;
 @Transactional(readOnly=true) public PageResponse<Response> list(User u,boolean archived,int page,int size){return PageResponse.from(goals.findByOwnerIdAndArchivedOrderByTargetDateAsc(u.getId(),archived,paging(page,size)).map(this::response));}
 public Response save(User u,String id,Request r){
  var g=id==null?new SavingsGoal():owned(u,id,true);
  if(id!=null&&!Objects.equals(g.getVersion(),r.version()))throw error(409,"Mục tiêu đã thay đổi. Tải lại trước khi sửa.");
  if(r.title()==null||r.title().isBlank()||r.title().length()>160||!validAmount(r.target()))throw error(400,"Nhập tên và số tiền lớn hơn 0, tối đa 1.000.000.000.000, không quá 2 số thập phân");
  String currency=r.currencyCode()==null?"VND":r.currencyCode().toUpperCase(Locale.ROOT);
  if(!currency.matches("[A-Z]{3}"))throw error(400,"Mã tiền tệ cần 3 chữ cái");
  if(id!=null&&!g.getCurrencyCode().equals(currency))throw error(400,"Không đổi tiền tệ của mục tiêu; tạo mục tiêu mới");
  if(r.note()!=null&&r.note().length()>1000)throw error(400,"Ghi chú tối đa 1000 ký tự");
  g.setOwnerId(u.getId());g.setTitle(r.title().trim());g.setTarget(r.target());g.setCurrencyCode(currency);g.setTargetDate(r.targetDate());g.setNote(r.note());g.setArchived(Boolean.TRUE.equals(r.archived()));if(id==null)g.setProgress(BigDecimal.ZERO);
  return response(goals.saveAndFlush(g));
 }
 public void archive(User u,String id,Long version){var g=owned(u,id,true);if(!Objects.equals(g.getVersion(),version))throw error(409,"Mục tiêu đã thay đổi");g.setArchived(true);}
 @Transactional(readOnly=true) public PageResponse<OperationResponse> history(User u,String id,int page,int size){owned(u,id,false);return PageResponse.from(operations.findByGoalIdOrderByCreatedAtDesc(id,paging(page,size)).map(this::response));}
 public OperationResponse record(User u,String id,OperationRequest r){
  var g=owned(u,id,true);
  if(r.operationId()==null||!r.operationId().matches("[A-Za-z0-9_-]{8,80}")||!Set.of("ADD","RELEASE").contains(Objects.toString(r.type(),""))||!validAmount(r.amount()))throw error(400,"Thao tác không hợp lệ; số tiền lớn hơn 0, tối đa 1.000.000.000.000, không quá 2 số thập phân");
  if(!g.getCurrencyCode().equals(r.currencyCode()))throw error(400,"Tiền tệ không khớp mục tiêu");
  if(r.note()!=null&&r.note().length()>1000)throw error(400,"Ghi chú tối đa 1000 ký tự");
  var existing=operations.findByGoalIdAndOperationId(id,r.operationId());
  if(existing.isPresent()){var o=existing.get();if(!o.getType().equals(r.type())||o.getAmount().compareTo(r.amount())!=0||!Objects.equals(o.getNote(),r.note()))throw error(409,"Mã thao tác đã dùng với nội dung khác");return response(o);}
  if(g.isArchived())throw error(400,"Mục tiêu đã lưu trữ");
  var next="ADD".equals(r.type())?g.getProgress().add(r.amount()):g.getProgress().subtract(r.amount());
  if(next.signum()<0)throw error(409,"Không thể rút quá tiến độ đã ghi nhận");if(next.compareTo(MAX_AMOUNT)>0)throw error(400,"Tổng tiến độ tối đa 1.000.000.000.000");
  g.setProgress(next);var o=new SavingsOperation();o.setGoalId(id);o.setOperationId(r.operationId());o.setType(r.type());o.setAmount(r.amount());o.setCurrencyCode(r.currencyCode());o.setNote(r.note());o.setCreatedAt(LocalDateTime.now(ZoneId.of("Asia/Ho_Chi_Minh")));return response(operations.save(o));
 }
 private SavingsGoal owned(User u,String id,boolean lock){return (lock?goals.lock(id,u.getId()):goals.findByIdAndOwnerId(id,u.getId())).orElseThrow(()->error(404,"Không tìm thấy mục tiêu của bạn"));}
 private org.springframework.data.domain.Pageable paging(int p,int s){return PageRequest.of(Math.max(0,p),Math.max(1,Math.min(50,s)));}
 private Response response(SavingsGoal g){return new Response(g.getId(),g.getTitle(),g.getTarget(),g.getProgress(),g.getCurrencyCode(),g.getTargetDate(),g.getNote(),g.isArchived(),g.getVersion());}
 private OperationResponse response(SavingsOperation o){return new OperationResponse(o.getId(),o.getOperationId(),o.getType(),o.getAmount(),o.getCurrencyCode(),o.getNote(),o.getCreatedAt());}
 private static ResponseStatusException error(int status,String m){return new ResponseStatusException(HttpStatus.valueOf(status),m);}
 private static final BigDecimal MAX_AMOUNT=new BigDecimal("1000000000000");
 private static boolean validAmount(BigDecimal value){return value!=null&&value.signum()>0&&value.scale()<=2&&value.compareTo(MAX_AMOUNT)<=0;}
}
