package com.fittrack.nutrition.planning;

import com.fittrack.common.dto.PageResponse;
import com.fittrack.common.exception.ConflictException;
import com.fittrack.common.exception.ResourceNotFoundException;
import com.fittrack.nutrition.dto.*;
import com.fittrack.nutrition.entity.Food;
import com.fittrack.nutrition.repository.FoodRepository;
import com.fittrack.nutrition.repository.NutritionCollectionRepository;
import com.fittrack.nutrition.service.NutritionService;
import com.fittrack.user.entity.User;
import jakarta.persistence.EntityManager;
import jakarta.persistence.LockModeType;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import tools.jackson.databind.ObjectMapper;
import java.time.*;
import java.time.temporal.ChronoUnit;
import java.util.*;
import static com.fittrack.nutrition.planning.PlanningDtos.*;

@Service @RequiredArgsConstructor
public class MealPlanningService {
    private final PlannedMealRepository meals;
    private final GroceryWeekRepository groceries;
    private final PlanningCopyRepository copies;
    private final FoodRepository foods;
    private final NutritionCollectionRepository collections;
    private final NutritionService nutrition;
    private final ObjectMapper json;
    private final EntityManager entityManager;
    private static final Set<String> TYPES=Set.of("BREAKFAST","LUNCH","DINNER","SNACK");

    @Transactional(readOnly=true)
    public PageResponse<MealResponse> list(User user,LocalDate from,LocalDate to,int page,int size) {
        range(from,to);
        return PageResponse.from(meals.findByUserAndDateBetweenOrderByDateAscCreatedAtAsc(user,from,to,
                PageRequest.of(Math.max(0,page),Math.clamp(size,1,50))).map(this::response));
    }

    @Transactional(readOnly=true)
    public WeekSummary summary(User user,LocalDate week) {
        monday(week); var rows=weekMeals(user,week);
        double c=0,p=0,h=0,f=0; int known=0,possible=0;
        for(var row:rows) {
            var totals=response(row).totals(); c+=totals.calories();p+=totals.protein();h+=totals.carbs();f+=totals.fat();
            known+=totals.knownMicronutrientValues();possible+=totals.possibleMicronutrientValues();
        }
        return new WeekSummary(week,rows.size(),new Totals(c,p,h,f,known,possible));
    }

    @Transactional
    public MealResponse create(User user,MealRequest request) {
        date(request.date()); lockOwner(user); ensureCapacity(user,request.date(),null);
        PlannedMeal value=new PlannedMeal(); value.setUser(user); apply(value,user,request);
        return response(meals.saveAndFlush(value));
    }

    @Transactional
    public MealResponse update(User user,String id,MealRequest request) {
        PlannedMeal value=owned(user,id); version(value.getVersion(),request.version()); editable(value);
        date(request.date()); lockOwner(user); ensureCapacity(user,request.date(),value.getDate());
        apply(value,user,request); return response(meals.saveAndFlush(value));
    }

    @Transactional
    public void delete(User user,String id,long version) {
        PlannedMeal value=owned(user,id); version(value.getVersion(),version); editable(value); meals.delete(value);
    }

    @Transactional
    public LogResult log(User user,String id,VersionRequest request) {
        PlannedMeal value=owned(user,id);
        if(value.getLoggedMealId()!=null) return new LogResult(value.getLoggedMealId(),true);
        version(value.getVersion(),request.version());
        if(value.getDate().isAfter(LocalDate.now(ZoneId.of("Asia/Ho_Chi_Minh"))))
            throw new IllegalArgumentException("Chỉ xác nhận đã ăn cho hôm nay hoặc ngày trước đó");
        CreateMealLogRequest actual=new CreateMealLogRequest(); actual.setLogDate(value.getDate()); actual.setMealType(value.getMealType());
        actual.setItems(readItems(value).stream().map(item->{
            // Revalidate at consumption time; NutritionService snapshots current catalog values into the actual diary.
            validateFood(item.foodId(),item.servingAmount(),item.servingUnit());
            CreateMealItemRequest r=new CreateMealItemRequest(); r.setFoodId(item.foodId());
            r.setServingAmount(item.servingAmount()); r.setServingUnit(item.servingUnit()); return r;
        }).toList());
        MealLogResponse result=nutrition.createMealLog(user,actual);
        value.setLoggedMealId(result.getId()); meals.saveAndFlush(value);
        return new LogResult(result.getId(),false);
    }

    @Transactional
    public int copyWeek(User user,CopyWeekRequest request) {
        monday(request.fromWeek()); monday(request.toWeek());
        if(request.fromWeek().equals(request.toWeek())) throw new IllegalArgumentException("Chọn tuần đích khác tuần nguồn");
        lockOwner(user); String fingerprint=request.fromWeek()+"/"+request.toWeek();
        var prior=copies.findByUserAndOperationId(user,request.operationId());
        if(prior.isPresent()) {
            if(!fingerprint.equals(prior.get().getFingerprint())) throw new ConflictException("Mã sao chép đã dùng cho tuần khác");
            return prior.get().getCopiedCount();
        }
        int count=importWeek(user,request.toWeek(),exportWeek(user,request.fromWeek()));
        PlanningCopy copy=new PlanningCopy(); copy.setUser(user); copy.setOperationId(request.operationId());
        copy.setFingerprint(fingerprint); copy.setCopiedCount(count); copies.save(copy); return count;
    }

    @Transactional(readOnly=true)
    public List<TemplateMeal> exportWeek(User user,LocalDate week) {
        monday(week);
        return weekMeals(user,week).stream().map(meal->new TemplateMeal((int)ChronoUnit.DAYS.between(week,meal.getDate()),
                meal.getMealType(),meal.getName(),readItems(meal).stream().map(item->
                new ItemRequest(item.foodId(),item.servingAmount(),item.servingUnit())).toList())).toList();
    }

    @Transactional
    public int importWeek(User user,LocalDate week,List<TemplateMeal> template) {
        monday(week); if(template==null||template.size()>140) throw new IllegalArgumentException("Tối đa 140 bữa trong mẫu tuần");
        if(weekMeals(user,week).size()+template.size()>140) throw new IllegalArgumentException("Tuần đích vượt 140 bữa");
        for(TemplateMeal meal:template) {
            if(meal.dayOffset()<0||meal.dayOffset()>6) throw new IllegalArgumentException("Ngày trong tuần không hợp lệ");
            create(user,new MealRequest(null,week.plusDays(meal.dayOffset()),meal.mealType(),meal.name(),null,null,null,meal.items()));
        }
        return template.size();
    }

    @Transactional(readOnly=true)
    public GroceryResponse groceryList(User user,LocalDate week) {
        monday(week); return groceries.findByUserAndWeek(user,week).map(this::groceryResponse)
                .orElseGet(()->new GroceryResponse(0,week,List.of()));
    }

    @Transactional
    public GroceryResponse regenerate(User user,GroceryRefreshRequest request) {
        GroceryWeek value=groceryLocked(user,request.week(),request.version());
        List<GroceryItemResponse> old=readGroceries(value);
        Map<String,GroceryItemResponse> oldGenerated=new LinkedHashMap<>();
        old.stream().filter(item->!item.manual()).forEach(item->oldGenerated.put(key(item.foodId(),item.unit()),item));
        Map<String,GroceryItemResponse> generated=new LinkedHashMap<>();
        for(PlannedMeal meal:weekMeals(user,request.week())) {
            for(ItemSnapshot item:readItems(meal)) {
                // Aggregate only identical food+unit. Never invent ingredients or infer liquid density.
                String key=key(item.foodId(),item.servingUnit());
                var before=generated.get(key); var previous=oldGenerated.get(key);
                generated.put(key,new GroceryItemResponse(previous==null?UUID.randomUUID().toString():previous.id(),item.foodId(),
                        item.foodName(),(before==null?0:before.amount())+item.servingAmount(),item.servingUnit(),
                        previous!=null&&previous.checked(),false,false));
            }
        }
        List<GroceryItemResponse> result=new ArrayList<>(generated.values().stream().map(item->{
            var previous=oldGenerated.get(key(item.foodId(),item.unit()));
            boolean changed=previous!=null&&previous.checked()&&Math.abs(previous.amount()-item.amount())>0.000001;
            return new GroceryItemResponse(item.id(),item.foodId(),item.name(),item.amount(),item.unit(),item.checked(),false,changed);
        }).toList());
        // Retain removed checked rows visibly as stale, and all manual items.
        old.stream().filter(item->item.manual()||(!generated.containsKey(key(item.foodId(),item.unit()))&&item.checked()))
                .forEach(item->result.add(item.manual()?item:new GroceryItemResponse(item.id(),item.foodId(),item.name(),item.amount(),item.unit(),true,false,true)));
        if(result.size()>1000) throw new IllegalArgumentException("Danh sách mua tối đa 1000 mục; xóa các mục không còn dùng");
        value.setItems(write(result)); return groceryResponse(groceries.saveAndFlush(value));
    }

    @Transactional
    public GroceryResponse addManual(User user,GroceryManualRequest request) {
        GroceryWeek value=groceryLocked(user,request.week(),request.version()); List<GroceryItemResponse> items=new ArrayList<>(readGroceries(value));
        if(items.size()>=1000) throw new IllegalArgumentException("Danh sách mua tối đa 1000 mục");
        items.add(new GroceryItemResponse(UUID.randomUUID().toString(),null,request.name().trim(),request.amount(),request.unit().trim(),false,true,false));
        value.setItems(write(items)); return groceryResponse(groceries.saveAndFlush(value));
    }

    @Transactional
    public GroceryResponse check(User user,String id,GroceryCheckRequest request,boolean delete) {
        GroceryWeek value=groceryLocked(user,request.week(),request.version()); List<GroceryItemResponse> items=new ArrayList<>(readGroceries(value));
        int index=-1; for(int i=0;i<items.size();i++) if(items.get(i).id().equals(id)) index=i;
        if(index<0) throw new ResourceNotFoundException("Không tìm thấy mục mua hàng");
        var old=items.get(index);
        if(delete) items.remove(index); else items.set(index,new GroceryItemResponse(old.id(),old.foodId(),old.name(),old.amount(),old.unit(),request.checked(),old.manual(),old.stale()));
        value.setItems(write(items)); return groceryResponse(groceries.saveAndFlush(value));
    }

    private void apply(PlannedMeal value,User user,MealRequest request) {
        date(request.date());
        if(request.name()==null||request.name().isBlank()||request.name().length()>160||!TYPES.contains(request.mealType()))
            throw new IllegalArgumentException("Tên và loại bữa ăn không hợp lệ");
        List<ItemRequest> items=request.items();
        if(request.collectionId()!=null&&!request.collectionId().isBlank()) {
            var collection=collections.findByIdAndUser(request.collectionId(),user).filter(c->Boolean.TRUE.equals(c.getActive()))
                    .orElseThrow(()->new ResourceNotFoundException("Không tìm thấy bữa ăn/công thức đã lưu"));
            double servings=request.servings()==null?1:request.servings();
            if(!Double.isFinite(servings)||servings<=0||servings>1000) throw new IllegalArgumentException("Khẩu phần không hợp lệ");
            double multiplier=servings/collection.getServings();
            items=collection.getItems().stream().map(i->new ItemRequest(i.getFood().getId(),i.getServingAmount()*multiplier,i.getServingUnit())).toList();
        }
        if(items==null||items.isEmpty()||items.size()>100) throw new IllegalArgumentException("Mỗi bữa cần 1–100 thực phẩm");
        value.setDate(request.date()); value.setMealType(request.mealType()); value.setName(request.name().trim()); value.setNotes(request.notes());
        value.setSnapshot(write(items.stream().map(this::snapshot).toList()));
    }

    private ItemSnapshot snapshot(ItemRequest item) {
        Food f=validateFood(item.foodId(),item.servingAmount(),item.servingUnit());
        double factor="SERVING".equals(item.servingUnit())?item.servingAmount():item.servingAmount()/f.getServingSizeGrams();
        return new ItemSnapshot(f.getId(),f.getName(),f.getUnit(),f.getServingSizeGrams(),item.servingAmount(),item.servingUnit(),
                scale(f.getCalories(),factor),scale(f.getProtein(),factor),scale(f.getCarbs(),factor),scale(f.getFat(),factor),
                scale(f.getFiber(),factor),scale(f.getSugar(),factor),scale(f.getSodium(),factor),scale(f.getPotassium(),factor),
                scale(f.getCalcium(),factor),scale(f.getIron(),factor),scale(f.getVitaminC(),factor),scale(f.getWater(),factor),
                f.getDataSourceType(),f.getDataSourceName(),f.getVerified());
    }

    private Food validateFood(String id,Double amount,String unit) {
        if(amount==null||!Double.isFinite(amount)||amount<=0||amount>100000||!Set.of("SERVING","GRAM","ML").contains(unit==null?"":unit))
            throw new IllegalArgumentException("Số lượng hoặc đơn vị thực phẩm không hợp lệ");
        Food f=foods.findById(id).filter(v->Boolean.TRUE.equals(v.getActive())&&"APPROVED".equals(v.getApprovalStatus()))
                .orElseThrow(()->new IllegalArgumentException("Thực phẩm đã ẩn/chưa duyệt, vui lòng chọn lại: "+id));
        if(!"SERVING".equals(unit)) {
            boolean liquid=f.getUnit()!=null&&f.getUnit().toLowerCase(Locale.ROOT).matches(".*(?:ml|lít|litre|liter).*");
            if(("ML".equals(unit)!=liquid)||f.getServingSizeGrams()==null||f.getServingSizeGrams()<=0)
                throw new IllegalArgumentException("Không tự đổi gram sang ml; thực phẩm cần khẩu phần phù hợp");
        }
        return f;
    }

    MealResponse response(PlannedMeal value) {
        List<ItemSnapshot> items=readItems(value); double c=0,p=0,h=0,f=0; int known=0;
        for(var i:items) {c+=zero(i.calories());p+=zero(i.protein());h+=zero(i.carbs());f+=zero(i.fat());
            for(Double n:Arrays.asList(i.fiber(),i.sugar(),i.sodium(),i.potassium(),i.calcium(),i.iron(),i.vitaminC(),i.water())) if(n!=null) known++;}
        return new MealResponse(value.getId(),value.getVersion(),value.getDate(),value.getMealType(),value.getName(),value.getNotes(),items,
                new Totals(c,p,h,f,known,items.size()*8),value.getLoggedMealId());
    }

    private GroceryWeek groceryLocked(User user,LocalDate week,Long expected) {
        monday(week); lockOwner(user);
        GroceryWeek value=groceries.lock(user,week).orElseGet(()->{GroceryWeek g=new GroceryWeek();g.setUser(user);g.setWeek(week);return groceries.saveAndFlush(g);});
        version(value.getVersion(),expected); return value;
    }
    private void lockOwner(User user) {entityManager.find(User.class,user.getId(),LockModeType.PESSIMISTIC_WRITE);}
    private void ensureCapacity(User user,LocalDate date,LocalDate oldDate) {
        LocalDate week=date.minusDays(date.getDayOfWeek().getValue()-1);
        if(oldDate!=null&&!oldDate.isBefore(week)&&!oldDate.isAfter(week.plusDays(6))) return;
        if(meals.countByUserAndDateBetween(user,week,week.plusDays(6))>=140)
            throw new IllegalArgumentException("Mỗi tuần tối đa 140 bữa dự kiến");
    }
    private PlannedMeal owned(User user,String id) {return meals.lock(id,user).orElseThrow(()->new ResourceNotFoundException("Không tìm thấy bữa ăn dự kiến"));}
    private static void version(long actual,Long expected) {if(expected==null||expected!=actual) throw new ConflictException("Dữ liệu đã thay đổi. Hãy tải lại trước khi lưu");}
    private static void editable(PlannedMeal meal) {if(meal.getLoggedMealId()!=null) throw new ConflictException("Bữa này đã ghi nhật ký; chỉnh tại nhật ký ăn uống");}
    private List<PlannedMeal> weekMeals(User user,LocalDate week) {
        List<PlannedMeal> result=meals.findByUserAndDateBetweenOrderByDateAscCreatedAtAsc(user,week,week.plusDays(6));
        if(result.size()>140) throw new IllegalArgumentException("Tuần vượt 140 bữa; thu hẹp dữ liệu trước khi thao tác"); return result;
    }
    private List<ItemSnapshot> readItems(PlannedMeal m) {return Arrays.asList(json.readValue(m.getSnapshot(),ItemSnapshot[].class));}
    private List<GroceryItemResponse> readGroceries(GroceryWeek g) {return Arrays.asList(json.readValue(g.getItems(),GroceryItemResponse[].class));}
    private GroceryResponse groceryResponse(GroceryWeek g) {return new GroceryResponse(g.getVersion(),g.getWeek(),readGroceries(g));}
    private String write(Object value) {return json.writeValueAsString(value);}
    private static String key(String food,String unit) {return food+"/"+unit;}
    private static Double scale(Double n,double f) {return n==null?null:n*f;}
    private static double zero(Double n) {return n==null?0:n;}
    private static void date(LocalDate date) {if(date==null||date.isBefore(LocalDate.of(2000,1,1))||date.isAfter(LocalDate.of(2100,12,31))) throw new IllegalArgumentException("Ngày phải trong 2000–2100");}
    private static void monday(LocalDate date) {date(date);if(date.getDayOfWeek()!=DayOfWeek.MONDAY)throw new IllegalArgumentException("Chọn ngày thứ Hai đầu tuần");}
    private static void range(LocalDate from,LocalDate to) {date(from);date(to);if(to.isBefore(from)||ChronoUnit.DAYS.between(from,to)>61)throw new IllegalArgumentException("Khoảng xem tối đa 62 ngày");}
}
