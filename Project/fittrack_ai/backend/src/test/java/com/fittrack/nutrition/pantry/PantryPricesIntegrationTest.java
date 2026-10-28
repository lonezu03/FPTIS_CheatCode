package com.fittrack.nutrition.pantry;
import com.fittrack.FittrackBackendApplication;
import com.fittrack.common.exception.*;
import com.fittrack.nutrition.entity.*;
import com.fittrack.nutrition.repository.*;
import com.fittrack.nutrition.planning.*;
import com.fittrack.nutrition.purchaseprices.*;
import com.fittrack.nutrition.service.NutritionConvenienceService;
import com.fittrack.nutrition.dto.NutritionConvenienceDtos.*;
import com.fittrack.user.entity.User;
import com.fittrack.user.repository.UserRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.test.context.ActiveProfiles;
import java.math.*;
import java.time.*;
import java.util.*;
import java.util.concurrent.*;
import static com.fittrack.nutrition.pantry.PantryDtos.*;
import static org.junit.jupiter.api.Assertions.*;
@SpringBootTest(classes=FittrackBackendApplication.class) @ActiveProfiles("test")
class PantryPricesIntegrationTest {
 @Autowired PantryService pantry;@Autowired PurchasePriceService prices;@Autowired UserRepository users;@Autowired FoodRepository foods;@Autowired MealLogRepository diary;
 @Autowired MealPlanningService planning;@Autowired NutritionConvenienceService convenience;
 private User user(){return users.save(User.builder().email("pantry-"+UUID.randomUUID()+"@example.com").password("encoded").fullName("Kho riêng").healthEnabled(true).financeEnabled(true).build());}
 private Food food(String unit,Double factor){return foods.save(Food.builder().name("Thực phẩm "+UUID.randomUUID()).unit(unit).servingSizeGrams(factor).active(true).approvalStatus("APPROVED").calories(100d).protein(10d).carbs(10d).fat(1d).build());}
 private BigDecimal n(String value){return new BigDecimal(value);}
 private LocalDate today(){return LocalDate.now(ZoneId.of("Asia/Ho_Chi_Minh"));}
 private Create create(Food f,String amount,String op){return new Create(f.getId(),"Tủ lạnh","SERVING",n(amount),today().plusDays(2),"Lô mới",op);}
 private PurchasePriceDtos.Input price(Food f,String amount,String unit,String cost,LocalDate day){return new PurchasePriceDtos.Input(null,f.getId(),n(amount),unit,n(cost),day,"Chợ",null,UUID.randomUUID().toString());}
 @Test void stockIdempotencyStaleAndInsufficientAreSafe(){
  User u=user();Food f=food("100g",100d);Create request=create(f,"2","new");var b=pantry.create(u,request);assertEquals(b.id(),pantry.create(u,request).id());
  assertThrows(ConflictException.class,()->pantry.create(u,create(f,"3","new")));
  Operate use=new Operate(b.version(),"CONSUME",n("1"),"Đã dùng","use");var after=pantry.operate(u,b.id(),use);assertEquals(0,after.quantity().compareTo(n("1")));assertEquals(after.version(),pantry.operate(u,b.id(),use).version());
  assertEquals(2,pantry.history(u,b.id(),0).totalElements());assertThrows(ConflictException.class,()->pantry.operate(u,b.id(),new Operate(b.version(),"ADD",n("1"),null,"stale")));
  assertThrows(ConflictException.class,()->pantry.operate(u,b.id(),new Operate(after.version(),"DISCARD",n("2"),null,"too-much")));
  assertThrows(IllegalArgumentException.class,()->pantry.operate(u,b.id(),new Operate(after.version(),"CORRECTION",n("0"),null,"fix")));
  assertTrue(diary.findByUserAndLogDate(u,today()).isEmpty());
 }
 @Test void adminCannotReadOrChangeOthersPantryAndPermissionRevocationApplies(){
  User u=user(),admin=user();admin.setRole("ADMIN");users.save(admin);var b=pantry.create(u,create(food("100g",100d),"2","private"));
  assertEquals(0,pantry.list(admin,true,0,20).totalElements());assertThrows(ResourceNotFoundException.class,()->pantry.history(admin,b.id(),0));
  assertThrows(ResourceNotFoundException.class,()->pantry.edit(admin,b.id(),new Edit(b.version(),"X",null,null,true)));
  u.setHealthEnabled(false);users.save(u);assertThrows(AccessDeniedException.class,()->pantry.list(u,true,0,20));
 }
 @Test void concurrentStockRetryNeverConsumesTwice() throws Exception {
  User u=user();var b=pantry.create(u,create(food("100g",100d),"3","seed"));var req=new Operate(b.version(),"CONSUME",n("1"),"test","one-consumption");
  try(var pool=Executors.newFixedThreadPool(2)){List<Future<Batch>> results=pool.invokeAll(List.<Callable<Batch>>of(()->pantry.operate(u,b.id(),req),()->pantry.operate(u,b.id(),req)));assertEquals(results.get(0).get().quantity(),results.get(1).get().quantity());}
  assertEquals(0,pantry.list(u,true,0,20).content().getFirst().quantity().compareTo(n("2")));assertEquals(2,pantry.history(u,b.id(),0).totalElements());
 }
 @Test void unitsNeverInferDensityOrMissingServingFactor(){
  Food milk=food("100ml",100d),unknown=food("phần",null);assertThrows(IllegalArgumentException.class,()->PantryQuantity.convert(milk,n("100"),"GRAM","ML"));
  assertNull(PantryQuantity.convert(unknown,n("100"),"GRAM","SERVING"));assertEquals(0,PantryQuantity.convert(milk,n("2"),"SERVING","ML").compareTo(n("200")));
 }
 @Test void stockSuggestionsUseExactFoodAndExcludeExpiredLots(){
  User u=user();Food f=food("100g",100d);convenience.create(u,new CollectionRequest("Món đã lưu",null,NutritionCollectionType.RECIPE,1d,List.of(new CollectionItemRequest(f.getId(),200d,"GRAM"))));
  var b=pantry.create(u,create(f,"2","recipe-stock"));assertTrue(pantry.suggestions(u).getFirst().sufficient());
  pantry.edit(u,b.id(),new Edit(b.version(),b.location(),today().minusDays(1),null,true));assertFalse(pantry.suggestions(u).getFirst().sufficient());
 }
 @Test void pricesRequireBothFlagsAndDoNotLeakToAdmin(){
  User u=user();Food f=food("100g",100d);var request=price(f,"100","GRAM","20000",today());var p=prices.save(u,null,request);assertEquals(p.id(),prices.save(u,null,request).id());
  User admin=user();admin.setRole("ADMIN");users.save(admin);assertEquals(0,prices.list(admin,true,null,0,20).totalElements());assertThrows(ResourceNotFoundException.class,()->prices.archive(admin,p.id(),p.version()));
  u.setFinanceEnabled(false);users.save(u);assertThrows(AccessDeniedException.class,()->prices.list(u,true,null,0,20));
 }
 @Test void weeklyCostUsesLatestCompatiblePastPriceAndUnknownIsNull(){
  User u=user();Food known=food("100g",100d),missing=food("phần",null);LocalDate week=today().minusDays(today().getDayOfWeek().getValue()-1);
  planning.create(u,new PlanningDtos.MealRequest(null,week,"BREAKFAST","Bữa dự kiến",null,null,null,List.of(new PlanningDtos.ItemRequest(known.getId(),2d,"SERVING"),new PlanningDtos.ItemRequest(missing.getId(),1d,"SERVING"))));
  prices.save(u,null,price(known,"100","GRAM","20000",today().minusDays(2)));prices.save(u,null,price(known,"100","GRAM","30000",today()));
  var before=prices.cost(u,week,today().minusDays(1));assertEquals(0,before.knownSubtotal().compareTo(n("40000")));assertEquals(1,before.pricedLines());assertEquals(50,before.coverage());assertNull(before.items().stream().filter(i->i.foodId().equals(missing.getId())).findFirst().orElseThrow().estimatedCost());
  assertEquals(0,prices.cost(u,week,today()).knownSubtotal().compareTo(n("60000")));assertTrue(diary.findByUserAndLogDate(u,week).isEmpty());
 }
 @Test void priceEditsAreVersionedAndArchivedPriceIsNotEstimated(){
  User u=user();Food f=food("100g",100d);var p=prices.save(u,null,price(f,"1","SERVING","10000",today()));
  var req=new PurchasePriceDtos.Input(p.version(),f.getId(),n("1"),"SERVING",n("12000"),today(),"Siêu thị",null,"edit");var edited=prices.save(u,p.id(),req);
  assertThrows(ConflictException.class,()->prices.save(u,p.id(),req));assertThrows(ConflictException.class,()->prices.archive(u,p.id(),p.version()));prices.archive(u,p.id(),edited.version());assertEquals(0,prices.list(u,true,null,0,20).totalElements());assertEquals(1,prices.list(u,false,null,0,20).totalElements());
 }
}
