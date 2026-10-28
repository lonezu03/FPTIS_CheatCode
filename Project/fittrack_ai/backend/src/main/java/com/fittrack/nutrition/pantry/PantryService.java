package com.fittrack.nutrition.pantry;
import com.fittrack.common.dto.PageResponse;
import com.fittrack.common.exception.*;
import com.fittrack.nutrition.entity.Food;
import com.fittrack.nutrition.repository.*;
import com.fittrack.user.entity.User;
import com.fittrack.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.math.*;
import java.nio.charset.StandardCharsets;
import java.security.*;
import java.time.*;
import java.util.*;
import static com.fittrack.nutrition.pantry.PantryDtos.*;
@Service @RequiredArgsConstructor
public class PantryService {
 private final PantryRepository batches; private final PantryOperationRepository operations;
 private final FoodRepository foods; private final UserRepository users; private final NutritionCollectionRepository collections;
 public static void permission(User u,boolean prices){
  if(!Boolean.TRUE.equals(u.getActive())||(!"ADMIN".equalsIgnoreCase(u.getRole())&&(!Boolean.TRUE.equals(u.getHealthEnabled())||(prices&&!Boolean.TRUE.equals(u.getFinanceEnabled())))))
   throw new AccessDeniedException(prices?"Cần quyền Dinh dưỡng và Tài chính":"Cần quyền Dinh dưỡng");
 }
 public static String digest(Object value){try{return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(value.toString().getBytes(StandardCharsets.UTF_8)));}catch(NoSuchAlgorithmException e){throw new IllegalStateException(e);}}
 public static void version(long actual,Long expected){if(expected==null||actual!=expected)throw new ConflictException("Dữ liệu đã thay đổi. Tải lại trước khi thao tác");}
 public static void date(LocalDate date){if(date!=null&&(date.getYear()<2000||date.getYear()>2100))throw new IllegalArgumentException("Ngày phải trong khoảng 2000–2100");}
 @Transactional(readOnly=true) public PageResponse<Batch> list(User u,boolean active,int page,int size){permission(u,false);return PageResponse.from(batches.findByUserAndActiveOrderByCreatedAtDesc(u,active,PageRequest.of(Math.max(0,page),Math.clamp(size,1,50))).map(this::view));}
 @Transactional public Batch create(User u,Create r){
  permission(u,false);lock(u);String fp=digest(r);var prior=operations.findByUserAndOperationId(u,r.operationId());
  if(prior.isPresent()){same(prior.get(),fp);return view(prior.get().getBatch());}
  date(r.expiresOn());Food food=food(r.foodId());PantryQuantity.validate(food,r.unit());
  PantryBatch b=new PantryBatch();b.setUser(u);b.setFood(food);b.setUnit(r.unit());b.setLocation(r.location().trim());b.setQuantity(r.quantity());b.setExpiresOn(r.expiresOn());b.setNote(r.note());
  batches.saveAndFlush(b);record(u,b,r.operationId(),fp,"ADD",r.quantity(),r.note());return view(b);
 }
 @Transactional public Batch edit(User u,String id,Edit r){permission(u,false);lock(u);PantryBatch b=owned(u,id);version(b.getVersion(),r.version());date(r.expiresOn());b.setLocation(r.location().trim());b.setExpiresOn(r.expiresOn());b.setNote(r.note());b.setActive(r.active());return view(batches.saveAndFlush(b));}
 @Transactional public Batch operate(User u,String id,Operate r){
  permission(u,false);lock(u);String fp=digest(id+":"+r);var prior=operations.findByUserAndOperationId(u,r.operationId());
  if(prior.isPresent()){same(prior.get(),fp);return view(prior.get().getBatch());}
  PantryBatch b=owned(u,id);version(b.getVersion(),r.version());if(!b.isActive())throw new ConflictException("Khôi phục lô trước khi thay đổi số lượng");
  if(!Set.of("ADD","CONSUME","DISCARD","CORRECTION").contains(r.type()))throw new IllegalArgumentException("Thao tác không hợp lệ");
  if(!r.type().equals("CORRECTION")&&r.amount().signum()<=0)throw new IllegalArgumentException("Số lượng phải lớn hơn 0");
  if(r.type().equals("CORRECTION")&&(r.note()==null||r.note().isBlank()))throw new IllegalArgumentException("Đối soát cần ghi lý do");
  BigDecimal next=switch(r.type()){case "ADD"->b.getQuantity().add(r.amount());case "CORRECTION"->r.amount();default->b.getQuantity().subtract(r.amount());};
  if(next.signum()<0)throw new ConflictException("Số lượng xuất vượt tồn kho");if(next.compareTo(new BigDecimal("1000000000"))>0)throw new IllegalArgumentException("Tồn kho vượt giới hạn");
  BigDecimal delta=next.subtract(b.getQuantity());b.setQuantity(next);batches.saveAndFlush(b);record(u,b,r.operationId(),fp,r.type(),delta,r.note());return view(b);
 }
 @Transactional(readOnly=true) public PageResponse<Operation> history(User u,String id,int page){permission(u,false);PantryBatch b=batches.findById(id).filter(x->x.getUser().getId().equals(u.getId())).orElseThrow(()->new ResourceNotFoundException("Không tìm thấy lô"));return PageResponse.from(operations.findByBatchAndUserOrderByCreatedAtDesc(b,u,PageRequest.of(Math.max(0,page),20)).map(o->new Operation(o.getId(),o.getType(),o.getAmount(),o.getBalanceAfter(),o.getNote(),o.getCreatedAt())));}
 @Transactional(readOnly=true) public List<Suggestion> suggestions(User u){
  permission(u,false);LocalDate today=LocalDate.now(ZoneId.of("Asia/Ho_Chi_Minh"));
  var stock=batches.findByUserAndActiveTrueAndQuantityGreaterThan(u,BigDecimal.ZERO).stream().filter(b->b.getExpiresOn()==null||!b.getExpiresOn().isBefore(today)).toList();
  return collections.findByUserAndActiveTrueOrderByUpdatedAtDesc(u).stream().limit(100).map(c->{
   Map<String,BigDecimal> needs=new LinkedHashMap<>();Map<String,Food> refs=new HashMap<>();List<String> missing=new ArrayList<>();
   for(var item:c.getItems()){
    Food f=item.getFood();if(!Boolean.TRUE.equals(f.getActive())||!"APPROVED".equals(f.getApprovalStatus())){missing.add(f.getName()+": không còn khả dụng trong kho thực phẩm");continue;}BigDecimal converted;
    try{converted=PantryQuantity.convert(f,BigDecimal.valueOf(item.getServingAmount()),item.getServingUnit(),"SERVING");}catch(IllegalArgumentException e){missing.add(f.getName()+": đơn vị không còn tương thích");continue;}
    String canonical=converted==null?item.getServingUnit():"SERVING",key=f.getId()+":"+canonical;refs.put(key,f);
    needs.merge(key,converted==null?BigDecimal.valueOf(item.getServingAmount()):converted,BigDecimal::add);
   }
   needs.forEach((key,need)->{Food f=refs.get(key);String unit=key.substring(key.lastIndexOf(':')+1);BigDecimal total=BigDecimal.ZERO;for(var b:stock)if(b.getFood().getId().equals(f.getId())){try{BigDecimal q=PantryQuantity.convert(f,b.getQuantity(),b.getUnit(),unit);if(q!=null)total=total.add(q);}catch(IllegalArgumentException ignored){/* Incompatible catalog units are unknown, not available stock. */}}
    if(total.compareTo(need)<0)missing.add(f.getName()+": chưa đủ tồn / thông tin quy đổi, còn cần "+need.subtract(total).stripTrailingZeros().toPlainString()+" "+switch(unit){case "GRAM"->"g";case "ML"->"ml";default->"khẩu phần";});});
   return new Suggestion(c.getId(),c.getName(),missing.isEmpty()&&!needs.isEmpty(),missing);
  }).toList();
 }
 private Food food(String id){return foods.findById(id).filter(f->Boolean.TRUE.equals(f.getActive())&&"APPROVED".equals(f.getApprovalStatus())).orElseThrow(()->new IllegalArgumentException("Thực phẩm chưa được duyệt hoặc đã lưu trữ"));}
 private void lock(User u){users.findByIdForUpdate(u.getId()).orElseThrow(()->new ResourceNotFoundException("Không tìm thấy tài khoản"));}
 private PantryBatch owned(User u,String id){return batches.lock(id,u).orElseThrow(()->new ResourceNotFoundException("Không tìm thấy lô"));}
 private void same(PantryOperation p,String fp){if(!p.getFingerprint().equals(fp))throw new ConflictException("Mã thao tác đã dùng cho nội dung khác");}
 private void record(User u,PantryBatch b,String op,String fp,String type,BigDecimal delta,String note){PantryOperation p=new PantryOperation();p.setUser(u);p.setBatch(b);p.setOperationId(op);p.setFingerprint(fp);p.setType(type);p.setAmount(delta);p.setBalanceAfter(b.getQuantity());p.setNote(note);operations.saveAndFlush(p);}
 private Batch view(PantryBatch b){return new Batch(b.getId(),b.getVersion(),b.getFood().getId(),b.getFood().getName(),b.getLocation(),b.getUnit(),b.getQuantity(),b.getExpiresOn(),b.getNote(),b.isActive());}
}
