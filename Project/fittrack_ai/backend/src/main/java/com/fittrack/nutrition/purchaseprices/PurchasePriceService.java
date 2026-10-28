package com.fittrack.nutrition.purchaseprices;
import com.fittrack.common.dto.PageResponse;
import com.fittrack.common.exception.*;
import com.fittrack.nutrition.entity.Food;
import com.fittrack.nutrition.repository.FoodRepository;
import com.fittrack.nutrition.pantry.*;
import com.fittrack.nutrition.planning.MealPlanningService;
import com.fittrack.user.entity.User;
import com.fittrack.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.math.*;
import java.time.*;
import java.util.*;
import static com.fittrack.nutrition.purchaseprices.PurchasePriceDtos.*;
@Service @RequiredArgsConstructor
public class PurchasePriceService {
 private final PurchasePriceRepository prices;private final FoodRepository foods;private final UserRepository users;private final MealPlanningService planning;
 @Transactional(readOnly=true) public PageResponse<Price> list(User u,boolean active,String foodId,int page,int size){PantryService.permission(u,true);return PageResponse.from(prices.list(u,active,foodId==null||foodId.isBlank()?null:foodId,PageRequest.of(Math.max(0,page),Math.clamp(size,1,50))).map(this::view));}
 @Transactional public Price save(User u,String id,Input r){
  PantryService.permission(u,true);users.findByIdForUpdate(u.getId()).orElseThrow(()->new ResourceNotFoundException("Không tìm thấy tài khoản"));
  String fp=PantryService.digest(r);PurchasePrice p;
  if(id==null){var old=prices.findByUserAndOperationId(u,r.operationId());if(old.isPresent()){if(!old.get().getFingerprint().equals(fp))throw new ConflictException("Mã thao tác đã dùng cho nội dung khác");return view(old.get());}p=new PurchasePrice();p.setUser(u);p.setOperationId(r.operationId());p.setFingerprint(fp);}
  else {p=owned(u,id);PantryService.version(p.getVersion(),r.version());if(!p.isActive())throw new ConflictException("Bản ghi đã lưu trữ");}
  PantryService.date(r.purchasedOn());if(r.purchasedOn().isAfter(LocalDate.now(ZoneId.of("Asia/Ho_Chi_Minh"))))throw new IllegalArgumentException("Ngày mua không thể ở tương lai");
  Food f=foods.findById(r.foodId()).filter(v->Boolean.TRUE.equals(v.getActive())&&"APPROVED".equals(v.getApprovalStatus())).orElseThrow(()->new IllegalArgumentException("Thực phẩm chưa được duyệt hoặc đã lưu trữ"));PantryQuantity.validate(f,r.unit());
  p.setFood(f);p.setAmount(r.amount());p.setUnit(r.unit());p.setTotalPrice(r.totalPrice());p.setPurchasedOn(r.purchasedOn());p.setStore(r.store());p.setNote(r.note());return view(prices.saveAndFlush(p));
 }
 @Transactional public void archive(User u,String id,long version){PantryService.permission(u,true);PurchasePrice p=owned(u,id);PantryService.version(p.getVersion(),version);p.setActive(false);prices.saveAndFlush(p);}
 @Transactional(readOnly=true) public WeekCost cost(User u,LocalDate week,LocalDate reference){
  PantryService.permission(u,true);PantryService.date(week);PantryService.date(reference);if(week.getDayOfWeek()!=DayOfWeek.MONDAY)throw new IllegalArgumentException("Tuần phải bắt đầu thứ Hai");
  if(reference.isAfter(LocalDate.now(ZoneId.of("Asia/Ho_Chi_Minh"))))throw new IllegalArgumentException("Mốc giá không thể ở tương lai");
  Map<String,BigDecimal> amounts=new LinkedHashMap<>();
  for(var meal:planning.exportWeek(u,week))for(var i:meal.items())amounts.merge(i.foodId()+":"+i.servingUnit(),BigDecimal.valueOf(i.servingAmount()),BigDecimal::add);
  Set<String> ids=new HashSet<>();amounts.keySet().forEach(k->ids.add(k.substring(0,k.lastIndexOf(':'))));
  Map<String,Food> catalog=new HashMap<>();foods.findAllById(ids).forEach(f->catalog.put(f.getId(),f));
  var candidates=ids.isEmpty()?List.<PurchasePrice>of():prices.candidates(u,ids,reference);List<CostLine> lines=new ArrayList<>();BigDecimal subtotal=BigDecimal.ZERO;int known=0;
  for(var e:amounts.entrySet()){
   int split=e.getKey().lastIndexOf(':');String foodId=e.getKey().substring(0,split),unit=e.getKey().substring(split+1);Food f=catalog.get(foodId);PurchasePrice selected=null;BigDecimal cost=null;
   if(f!=null)for(var p:candidates)if(p.getFood().getId().equals(foodId)){try{BigDecimal q=PantryQuantity.convert(f,e.getValue(),unit,p.getUnit());if(q!=null){selected=p;cost=q.multiply(p.getTotalPrice()).divide(p.getAmount(),0,RoundingMode.HALF_UP);break;}}catch(IllegalArgumentException ignored){/* Try the next price with compatible units, never infer density. */}}
   if(cost!=null){subtotal=subtotal.add(cost);if(subtotal.compareTo(new BigDecimal("9000000000000000"))>0)throw new IllegalArgumentException("Ước tính vượt phạm vi tiền an toàn. Kiểm tra lại giá và số lượng mua");known++;}
   lines.add(new CostLine(foodId,f==null?"Thực phẩm không còn khả dụng":f.getName(),e.getValue(),unit,cost,selected==null?null:selected.getId(),selected==null?null:selected.getPurchasedOn(),selected==null?null:selected.getStore(),cost==null?"Chưa có giá tương thích tại hoặc trước mốc ngày":null));
  }
  return new WeekCost(week,reference,"VND",subtotal,known,lines.size(),lines.isEmpty()?0:100d*known/lines.size(),lines);
 }
 private PurchasePrice owned(User u,String id){return prices.lock(id,u).orElseThrow(()->new ResourceNotFoundException("Không tìm thấy giá mua"));}
 private Price view(PurchasePrice p){return new Price(p.getId(),p.getVersion(),p.getFood().getId(),p.getFood().getName(),p.getAmount(),p.getUnit(),p.getTotalPrice(),p.getTotalPrice().divide(p.getAmount(),3,RoundingMode.HALF_UP),"VND",p.getPurchasedOn(),p.getStore(),p.getNote(),p.isActive());}
}
