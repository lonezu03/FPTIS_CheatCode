package com.fittrack.sharing;

import com.fittrack.common.dto.PageResponse;
import com.fittrack.user.entity.User;
import com.fittrack.user.repository.UserRepository;
import com.fittrack.workout.repository.ExerciseRepository;
import com.fittrack.workoutplan.dto.CreateWorkoutPlanRequest;
import com.fittrack.workoutplan.service.WorkoutPlanService;
import com.fittrack.nutrition.repository.FoodRepository;
import com.fittrack.nutrition.repository.NutritionCollectionRepository;
import com.fittrack.nutrition.dto.NutritionConvenienceDtos.*;
import com.fittrack.nutrition.entity.NutritionCollectionType;
import com.fittrack.nutrition.service.NutritionConvenienceService;
import com.fittrack.nutrition.planning.MealPlanningService;
import com.fittrack.nutrition.planning.PlanningDtos.TemplateMeal;
import jakarta.validation.constraints.*;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;
import tools.jackson.databind.ObjectMapper;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.*;
import java.util.*;

@Service @RequiredArgsConstructor
public class TemplateShareService {
    public record Create(@NotBlank String kind, @NotBlank String sourceId,
                         @NotBlank @Email String recipientEmail,
                         @NotBlank @Size(max=100) String operationId,
                         @Min(1) @Max(30) Integer expiresInDays) {}
    public record Accept(LocalDate targetWeek) {}
    public record CopyResult(String kind, String id, int count) {}
    public record View(String id, String kind, String title, String ownerName, String recipientName,
                       Boolean active, LocalDateTime createdAt, LocalDateTime expiresAt,
                       LocalDateTime copiedAt, Long version) {}
    public record Preview(View share, Object template, List<String> unavailableItems, Map<String,String> itemNames) {}
    private final TemplateShareRepository shares;
    private final UserRepository users;
    private final WorkoutPlanService plans;
    private final ExerciseRepository exercises;
    private final NutritionCollectionRepository collections;
    private final NutritionConvenienceService nutrition;
    private final FoodRepository foods;
    private final MealPlanningService mealPlanning;
    private final ObjectMapper json;
    private LocalDateTime now() { return LocalDateTime.now(ZoneId.of("Asia/Ho_Chi_Minh")); }
    private boolean admin(User user) { return "ADMIN".equals(user.getRole()); }
    private Set<String> allowed(User user) {
        Set<String> kinds = new HashSet<>();
        if (admin(user) || Boolean.TRUE.equals(user.getFitnessEnabled())) kinds.add("WORKOUT_PLAN");
        if (admin(user) || Boolean.TRUE.equals(user.getHealthEnabled())) kinds.addAll(Set.of("MEAL_COLLECTION","MEAL_WEEK"));
        return kinds;
    }
    private void permission(User user, String kind) {
        if (!Boolean.TRUE.equals(user.getActive()) || !allowed(user).contains(kind))
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Chưa có quyền với loại bản mẫu này");
    }
    private ResponseStatusException notFound() { return new ResponseStatusException(HttpStatus.NOT_FOUND, "Không tìm thấy chia sẻ"); }
    @Transactional(readOnly=true)
    public PageResponse<View> list(User user, boolean inbox, int page, int size) {
        if (allowed(user).isEmpty()) throw new ResponseStatusException(HttpStatus.FORBIDDEN);
        var pagination = PageRequest.of(Math.max(page,0), Math.min(Math.max(size,1),50));
        var rows = inbox ? shares.findByRecipientAndKindInOrderByCreatedAtDesc(user,allowed(user),pagination)
                : shares.findByOwnerAndKindInOrderByCreatedAtDesc(user,allowed(user),pagination);
        return PageResponse.from(rows.map(this::view));
    }
    @Transactional
    public View create(User actor, Create input) {
        permission(actor,input.kind());
        if (input.expiresInDays()!=null && (input.expiresInDays()<1 || input.expiresInDays()>30)) throw new IllegalArgumentException("Hiệu lực từ 1 đến 30 ngày");
        users.findByIdForUpdate(actor.getId()).orElseThrow(this::notFound);
        String digest = digest(json.writeValueAsString(input));
        var previous = shares.findByOwnerAndOperationId(actor,input.operationId());
        if (previous.isPresent()) {
            if (!previous.get().getRequestDigest().equals(digest)) throw new ResponseStatusException(HttpStatus.CONFLICT,"Mã thao tác đã dùng cho yêu cầu khác");
            return view(previous.get());
        }
        var recipient = users.findByEmail(input.recipientEmail().trim().toLowerCase(Locale.ROOT))
                .filter(u -> Boolean.TRUE.equals(u.getActive()) && !u.getId().equals(actor.getId()) && allowed(u).contains(input.kind()))
                .orElseThrow(() -> new IllegalArgumentException("Không thể chia sẻ tới tài khoản này. Kiểm tra email và quyền module của người nhận."));
        Object snapshot; String title;
        switch(input.kind()) {
            case "WORKOUT_PLAN" -> {
                var source = plans.getPlanDetail(actor,input.sourceId());
                Map<String,Object> response = map(source);
                snapshot = planRequest(response); title = source.getName();
            }
            case "MEAL_COLLECTION" -> {
                var source = collections.findByIdAndUser(input.sourceId(),actor)
                        .filter(c -> Boolean.TRUE.equals(c.getActive())).orElseThrow(this::notFound);
                snapshot = new CollectionRequest(source.getName(),source.getDescription(),source.getType(),source.getServings(),
                        source.getItems().stream().map(i -> new CollectionItemRequest(i.getFood().getId(),i.getServingAmount(),i.getServingUnit())).toList());
                title = source.getName();
            }
            case "MEAL_WEEK" -> {
                LocalDate week = monday(LocalDate.parse(input.sourceId()));
                var meals = mealPlanning.exportWeek(actor,week);
                if (meals.isEmpty()) throw new IllegalArgumentException("Tuần chưa có thực đơn để chia sẻ");
                snapshot = meals; title = "Thực đơn tuần " + week;
            }
            default -> throw new IllegalArgumentException("Loại bản mẫu không hợp lệ");
        }
        String encoded = json.writeValueAsString(snapshot);
        if (encoded.length()>1_000_000) throw new IllegalArgumentException("Bản mẫu quá lớn để chia sẻ");
        var share = new TemplateShare(); share.setOwner(actor); share.setRecipient(recipient);
        share.setKind(input.kind()); share.setSourceId(input.sourceId()); share.setTitle(title.substring(0,Math.min(title.length(),180)));
        share.setSnapshot(encoded); share.setOperationId(input.operationId()); share.setRequestDigest(digest);
        share.setActive(true); share.setCreatedAt(now()); share.setExpiresAt(now().plusDays(input.expiresInDays()==null?7:input.expiresInDays()));
        return view(shares.saveAndFlush(share));
    }
    @Transactional(readOnly=true)
    public Preview preview(User actor,String id) {
        var share = shares.findById(id).orElseThrow(this::notFound);
        boolean owner = share.getOwner().getId().equals(actor.getId());
        if (!owner && !share.getRecipient().getId().equals(actor.getId())) throw notFound();
        permission(actor,share.getKind());
        if (!owner) usable(share);
        return new Preview(view(share), json.readValue(share.getSnapshot(),Object.class), unavailable(share), itemNames(share));
    }
    @Transactional
    public CopyResult accept(User actor,String id,Accept input) {
        var share = shares.locked(id).orElseThrow(this::notFound);
        if (!share.getRecipient().getId().equals(actor.getId())) throw notFound();
        permission(actor,share.getKind()); usable(share);
        if (share.getCopiedAt()!=null) {
            var previous=json.readValue(share.getCopyResult(),CopyResult.class);
            if ("MEAL_WEEK".equals(share.getKind()) && (input==null || !previous.id().equals(String.valueOf(input.targetWeek()))))
                throw new ResponseStatusException(HttpStatus.CONFLICT,"Chia sẻ này đã sao chép vào tuần khác");
            return previous;
        }
        if (!unavailable(share).isEmpty()) throw new ResponseStatusException(HttpStatus.CONFLICT,"Bản mẫu có món/bài tập chưa được duyệt hoặc đã lưu trữ. Nhờ người gửi cập nhật và chia sẻ lại.");
        CopyResult result;
        switch(share.getKind()) {
            case "WORKOUT_PLAN" -> {
                var request=json.readValue(share.getSnapshot(),CreateWorkoutPlanRequest.class);
                request.setName(copyName(request.getName(),255)); request.setVersion(null);
                result=new CopyResult(share.getKind(),plans.createPlan(actor,request).getId(),1);
            }
            case "MEAL_COLLECTION" -> {
                var source=json.readValue(share.getSnapshot(),CollectionRequest.class);
                var request=new CollectionRequest(copyName(source.name(),160),source.description(),source.type(),source.servings(),source.items());
                result=new CopyResult(share.getKind(),nutrition.create(actor,request).id(),1);
            }
            case "MEAL_WEEK" -> {
                if(input==null || input.targetWeek()==null) throw new IllegalArgumentException("Chọn ngày thứ Hai của tuần đích");
                LocalDate week=monday(input.targetWeek());
                int count=mealPlanning.importWeek(actor,week,Arrays.asList(json.readValue(share.getSnapshot(),TemplateMeal[].class)));
                result=new CopyResult(share.getKind(),week.toString(),count);
            }
            default -> throw new IllegalArgumentException("Loại bản mẫu không hợp lệ");
        }
        share.setCopiedAt(now()); share.setCopyResult(json.writeValueAsString(result)); shares.saveAndFlush(share); return result;
    }
    @Transactional
    public View revoke(User actor,String id,long version) {
        var share=shares.locked(id).orElseThrow(this::notFound);
        if(!share.getOwner().getId().equals(actor.getId())) throw notFound();
        permission(actor,share.getKind());
        if(share.getVersion()!=version) throw new ResponseStatusException(HttpStatus.CONFLICT,"Chia sẻ đã thay đổi, hãy tải lại");
        share.setActive(false); return view(shares.saveAndFlush(share));
    }
    private void usable(TemplateShare share) {
        if (!share.getActive() || !share.getExpiresAt().isAfter(now()) || !Boolean.TRUE.equals(share.getOwner().getActive())) throw notFound();
        permission(share.getOwner(),share.getKind());
    }
    @SuppressWarnings("unchecked") private Map<String,Object> map(Object source) { return json.convertValue(source,Map.class); }
    @SuppressWarnings("unchecked") private List<Map<String,Object>> list(Object source) { return source instanceof List<?> values ? values.stream().map(v->(Map<String,Object>)v).toList() : List.of(); }
    private Map<String,Object> pick(Map<String,Object> source,List<String> keys) {
        Map<String,Object> result=new LinkedHashMap<>(); for(var key:keys) if(source.containsKey(key))result.put(key,source.get(key));return result;
    }
    private Object planRequest(Map<String,Object> response) {
        var result=pick(response,List.of("name","description"));
        result.put("days",list(response.get("days")).stream().map(day->{
            var d=pick(day,List.of("name","dayOrder")); d.put("exercises",list(day.get("exercises")).stream()
                .map(e->pick(e,List.of("exerciseId","exerciseOrder","targetSets","targetReps","targetWeight","targetRir","restSeconds","minReps","maxReps","coachingNote","groupKey","groupType","groupRounds","betweenExerciseRestSeconds","betweenRoundRestSeconds"))).toList());return d;
        }).toList()); return result;
    }
    private List<String> unavailable(TemplateShare share) {
        var ids=itemIds(share);var available=new HashSet<String>();
        if("WORKOUT_PLAN".equals(share.getKind()))exercises.findAllById(ids).stream().filter(e->Boolean.TRUE.equals(e.getActive())&&"APPROVED".equals(String.valueOf(e.getApprovalStatus()))).forEach(e->available.add(e.getId()));
        else foods.findAllById(ids).stream().filter(f->Boolean.TRUE.equals(f.getActive())&&"APPROVED".equals(String.valueOf(f.getApprovalStatus()))).forEach(f->available.add(f.getId()));
        return ids.stream().filter(id->!available.contains(id)).toList();
    }
    private Map<String,String> itemNames(TemplateShare share){
        Map<String,String> result=new LinkedHashMap<>();var ids=itemIds(share);
        if("WORKOUT_PLAN".equals(share.getKind()))exercises.findAllById(ids).forEach(e->result.put(e.getId(),e.getName()));
        else foods.findAllById(ids).forEach(f->result.put(f.getId(),f.getName()));return result;
    }
    private Set<String> itemIds(TemplateShare share) {
        Set<String> ids=new LinkedHashSet<>(); var data=json.readValue(share.getSnapshot(),Object.class);
        if("WORKOUT_PLAN".equals(share.getKind())) {
            for(var day:list(map(data).get("days"))) for(var e:list(day.get("exercises")))ids.add(String.valueOf(e.get("exerciseId")));
            return ids;
        }
        if("MEAL_COLLECTION".equals(share.getKind())) for(var i:list(map(data).get("items")))ids.add(String.valueOf(i.get("foodId")));
        else for(var meal:list(data))for(var i:list(meal.get("items")))ids.add(String.valueOf(i.get("foodId")));
        return ids;
    }
    private View view(TemplateShare s){return new View(s.getId(),s.getKind(),s.getTitle(),s.getOwner().getFullName(),s.getRecipient().getFullName(),s.getActive(),s.getCreatedAt(),s.getExpiresAt(),s.getCopiedAt(),s.getVersion());}
    private LocalDate monday(LocalDate date){if(date.getDayOfWeek()!=DayOfWeek.MONDAY)throw new IllegalArgumentException("Chọn ngày thứ Hai của tuần");return date;}
    private String copyName(String name,int max){String suffix=" (bản sao)";return name.substring(0,Math.min(name.length(),max-suffix.length()))+suffix;}
    private String digest(String value){try{return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(value.getBytes(StandardCharsets.UTF_8)));}catch(Exception e){throw new IllegalStateException(e);}}
}
