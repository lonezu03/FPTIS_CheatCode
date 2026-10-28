package com.fittrack.nutrition.planning;

import com.fittrack.FittrackBackendApplication;
import com.fittrack.common.exception.ConflictException;
import com.fittrack.common.exception.ResourceNotFoundException;
import com.fittrack.nutrition.entity.Food;
import com.fittrack.nutrition.entity.NutritionDayStatus;
import com.fittrack.nutrition.repository.FoodRepository;
import com.fittrack.nutrition.repository.MealLogRepository;
import com.fittrack.nutrition.repository.NutritionDayStateRepository;
import com.fittrack.nutrition.service.NutritionConvenienceService;
import com.fittrack.nutrition.dto.NutritionConvenienceDtos.*;
import com.fittrack.nutrition.entity.NutritionCollectionType;
import com.fittrack.user.entity.User;
import com.fittrack.user.repository.UserRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import java.time.*;
import java.util.*;
import java.util.concurrent.*;
import static com.fittrack.nutrition.planning.PlanningDtos.*;
import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest(classes=FittrackBackendApplication.class) @ActiveProfiles("test")
class MealPlanningIntegrationTest {
    @Autowired MealPlanningService service;
    @Autowired UserRepository users;
    @Autowired FoodRepository foods;
    @Autowired MealLogRepository diary;
    @Autowired NutritionDayStateRepository dayStates;
    @Autowired NutritionConvenienceService convenience;

    private User user() {return users.save(User.builder().email("planning-"+UUID.randomUUID()+"@example.com").password("encoded").fullName("Planning").role("USER").healthEnabled(true).build());}
    private Food food(String name,String unit) {return foods.save(Food.builder().name(name).unit(unit).servingSizeGrams(100.0).calories(200.0).protein(10.0).carbs(20.0).fat(4.0).active(true).approvalStatus("APPROVED").build());}
    private LocalDate week() {LocalDate d=LocalDate.now(ZoneId.of("Asia/Ho_Chi_Minh")).minusWeeks(1);return d.minusDays(d.getDayOfWeek().getValue()-1);}
    private MealRequest request(Food food,LocalDate date,double amount,String unit) {return new MealRequest(null,date,"BREAKFAST","Bữa dự kiến","Ghi chú riêng",null,null,List.of(new ItemRequest(food.getId(),amount,unit)));}

    @Test void planningDoesNotWriteDiaryAndSnapshotsDoNotChangeWithCatalog() {
        User u=user(); Food f=food("Cơm","100g"); var planned=service.create(u,request(f,week(),2,"SERVING"));
        assertEquals(400,planned.totals().calories()); assertEquals(0,planned.totals().knownMicronutrientValues());
        assertNull(planned.items().getFirst().iron()); assertTrue(diary.findByUserAndLogDate(u,week()).isEmpty());
        f.setName("Tên mới");f.setCalories(999.0);foods.save(f);
        var loaded=service.list(u,week(),week().plusDays(6),0,30).content().getFirst();
        assertEquals("Cơm",loaded.items().getFirst().foodName());assertEquals(400,loaded.totals().calories());
        User admin=user();admin.setRole("ADMIN");users.save(admin);
        assertEquals(0,service.list(admin,week(),week().plusDays(6),0,30).totalElements());
        assertThrows(ResourceNotFoundException.class,()->service.update(admin,planned.id(),new MealRequest(planned.version(),week(),"DINNER","Không",null,null,null,List.of(new ItemRequest(f.getId(),1.0,"SERVING")))));
    }

    @Test void concurrentConsumptionCreatesOnlyOneDiaryAndNeverCompletesDay() throws Exception {
        User u=user();Food f=food("Trứng","100g");var planned=service.create(u,request(f,week(),1,"SERVING"));
        try(var executor=Executors.newFixedThreadPool(2)) {
            List<Future<LogResult>> results=executor.invokeAll(List.of(()->service.log(u,planned.id(),new VersionRequest(planned.version())),()->service.log(u,planned.id(),new VersionRequest(planned.version()))));
            assertEquals(results.get(0).get().mealLogId(),results.get(1).get().mealLogId());
        }
        assertEquals(1,diary.findByUserAndLogDate(u,week()).size());
        assertEquals(NutritionDayStatus.PARTIAL,dayStates.findByUserAndLogDate(u,week()).orElseThrow().getStatus());
        assertThrows(ConflictException.class,()->service.delete(u,planned.id(),0));
    }

    @Test void futureAndUnavailableFoodsCannotBeConsumed() {
        User u=user();Food f=food("Gà","100g");var planned=service.create(u,request(f,week(),1,"SERVING"));
        f.setApprovalStatus("PENDING");foods.save(f);
        assertThrows(IllegalArgumentException.class,()->service.log(u,planned.id(),new VersionRequest(planned.version())));
        assertTrue(diary.findByUserAndLogDate(u,week()).isEmpty());
        f.setApprovalStatus("APPROVED");foods.save(f);
        var future=service.create(u,request(f,LocalDate.now().plusDays(2),1,"SERVING"));
        assertThrows(IllegalArgumentException.class,()->service.log(u,future.id(),new VersionRequest(future.version())));
    }

    @Test void staleEditsRejectedAndUnknownUnitsNeverInferDensity() {
        User u=user();Food f=food("Sữa","100ml");
        assertThrows(IllegalArgumentException.class,()->service.create(u,request(f,week(),100,"GRAM")));
        var planned=service.create(u,request(f,week(),150,"ML"));assertEquals(300,planned.totals().calories());
        var updated=service.update(u,planned.id(),new MealRequest(planned.version(),week(),"DINNER","Sữa tối",null,null,null,List.of(new ItemRequest(f.getId(),1.0,"SERVING"))));
        assertTrue(updated.version()>planned.version());
        assertThrows(ConflictException.class,()->service.update(u,planned.id(),new MealRequest(planned.version(),week(),"DINNER","Cũ",null,null,null,List.of(new ItemRequest(f.getId(),1.0,"SERVING")))));
    }

    @Test void groceriesRegenerationIsNotAdditiveAndRetainsManualAndChecked() {
        User u=user();Food f=food("Khoai","100g");
        var first=service.create(u,request(f,week(),100,"GRAM"));
        service.create(u,request(f,week().plusDays(1),200,"GRAM"));
        service.create(u,request(f,week().plusDays(2),1,"SERVING"));
        var list=service.regenerate(u,new GroceryRefreshRequest(week(),0L));assertEquals(2,list.items().size());
        var grams=list.items().stream().filter(i->i.unit().equals("GRAM")).findFirst().orElseThrow();assertEquals(300,grams.amount());
        list=service.check(u,grams.id(),new GroceryCheckRequest(week(),list.version(),true),false);
        list=service.addManual(u,new GroceryManualRequest(week(),list.version(),"Muối",1.0,"gói"));
        var regenerated=service.regenerate(u,new GroceryRefreshRequest(week(),list.version()));
        assertEquals(3,regenerated.items().size()); assertEquals(300,regenerated.items().stream().filter(i->i.unit().equals("GRAM")).findFirst().orElseThrow().amount());
        assertTrue(regenerated.items().stream().anyMatch(GroceryItemResponse::manual));assertTrue(regenerated.items().stream().anyMatch(GroceryItemResponse::checked));
        service.delete(u,first.id(),first.version());
        var reduced=service.regenerate(u,new GroceryRefreshRequest(week(),regenerated.version()));
        var changed=reduced.items().stream().filter(i->i.unit().equals("GRAM")).findFirst().orElseThrow();
        assertEquals(200,changed.amount());assertTrue(changed.checked());assertTrue(changed.stale());
        assertThrows(ConflictException.class,()->service.regenerate(u,new GroceryRefreshRequest(week(),regenerated.version())));
        User other=user();assertTrue(service.groceryList(other,week()).items().isEmpty());
        assertThrows(ResourceNotFoundException.class,()->service.check(other,grams.id(),new GroceryCheckRequest(week(),0L,true),false));
    }

    @Test void copyAndShareExportAreTemplatesOnlyAndCopyRetriesAreIdempotent() {
        User u=user();Food f=food("Cá","100g");var planned=service.create(u,request(f,week(),1,"SERVING"));
        service.log(u,planned.id(),new VersionRequest(planned.version()));
        var template=service.exportWeek(u,week());assertEquals(1,template.size());assertEquals(0,template.getFirst().dayOffset());
        var copy=new CopyWeekRequest(week(),week().plusWeeks(1),"operation-copy");
        assertEquals(1,service.copyWeek(u,copy));assertEquals(1,service.copyWeek(u,copy));
        var target=service.list(u,copy.toWeek(),copy.toWeek().plusDays(6),0,30);assertEquals(1,target.totalElements());
        assertNull(target.content().getFirst().loggedMealId());assertNull(target.content().getFirst().notes());
        assertTrue(diary.findByUserAndLogDate(u,copy.toWeek()).isEmpty());
        assertThrows(ConflictException.class,()->service.copyWeek(u,new CopyWeekRequest(week(),week().plusWeeks(2),"operation-copy")));
        f.setActive(false);foods.save(f);
        assertThrows(IllegalArgumentException.class,()->service.importWeek(user(),week(),template));
    }

    @Test void collectionsReuseTheirServingScaleAndCreateIndependentSnapshot() {
        User u=user();Food f=food("Yến mạch","100g");
        var collection=convenience.create(u,new CollectionRequest("Bữa đã lưu",null,NutritionCollectionType.RECIPE,2.0,List.of(new CollectionItemRequest(f.getId(),200.0,"GRAM"))));
        var planned=service.create(u,new MealRequest(null,week(),"BREAKFAST","Một phần",null,collection.id(),1.0,null));
        assertEquals(100,planned.items().getFirst().servingAmount());assertEquals(200,planned.totals().calories());
        convenience.delete(u,collection.id());assertEquals(1,service.exportWeek(u,week()).size());
    }

    @Test void boundsAndMondayValidationAreEnforced() {
        User u=user();
        assertThrows(IllegalArgumentException.class,()->service.list(u,week(),week().plusDays(62),0,30));
        assertThrows(IllegalArgumentException.class,()->service.groceryList(u,week().plusDays(1)));
        assertThrows(IllegalArgumentException.class,()->service.importWeek(u,week(),List.of(new TemplateMeal(8,"DINNER","Sai",List.of()))));
    }

    @Test void weeklySummaryCoversEveryMealNotOnlyFirstPageAndIsOwnerScoped() {
        User u=user();Food f=food("Cơm cả tuần","100g");
        for(int i=0;i<31;i++) service.create(u,request(f,week().plusDays(i%7),1,"SERVING"));
        assertEquals(30,service.list(u,week(),week().plusDays(6),0,30).content().size());
        var summary=service.summary(u,week());assertEquals(31,summary.plannedMealCount());
        assertEquals(6200,summary.totals().calories());assertEquals(310,summary.totals().protein());
        assertEquals(31*8,summary.totals().possibleMicronutrientValues());assertEquals(0,summary.totals().knownMicronutrientValues());
        assertEquals(0,service.summary(user(),week()).plannedMealCount());
        assertTrue(diary.findByUserAndLogDate(u,week()).isEmpty());
    }
}
