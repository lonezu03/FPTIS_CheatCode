package com.fittrack.catalogimport;

import com.fittrack.nutrition.dto.*;
import com.fittrack.nutrition.entity.Food;
import com.fittrack.nutrition.repository.FoodRepository;
import com.fittrack.nutrition.service.FoodService;
import com.fittrack.workout.dto.*;
import com.fittrack.workout.entity.Exercise;
import com.fittrack.workout.repository.ExerciseRepository;
import com.fittrack.workout.service.ExerciseService;
import com.fittrack.user.entity.User;
import jakarta.persistence.EntityManager;
import jakarta.persistence.LockModeType;
import jakarta.validation.Validator;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.BeanWrapperImpl;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.http.HttpStatus;
import tools.jackson.databind.ObjectMapper;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.LocalDateTime;
import java.util.*;

@Service @RequiredArgsConstructor
public class CatalogImportService {
    private final CatalogImportRepository batches;
    private final ExerciseRepository exercises;
    private final FoodRepository foods;
    private final ExerciseService exerciseService;
    private final FoodService foodService;
    private final ObjectMapper json;
    private final Validator validator;
    private final EntityManager em;
    private final com.fittrack.common.media.MediaStorageService media;
    private final CatalogImportLookup lookup;
    public record Row(int number,Map<String,String> values,Map<String,String> before,List<String> errors,List<String> warnings,String suggestedAction,String resultId,Map<String,String> after) {}
    public record Batch(String id,String kind,LocalDateTime createdAt,LocalDateTime committedAt,List<Row> rows) {}
    public record BatchSummary(String id,String kind,LocalDateTime createdAt,LocalDateTime committedAt,int rowCount,long importedCount,long errorCount) {}
    public record Selection(int number,String action,List<String> clearFields) {}
    public record Commit(List<Selection> selections) {}
    private static final List<String> EXERCISE=List.of("id","name","muscleGroup","equipment","description","imageUrl");
    private static final List<String> FOOD=List.of("id","name","unit","basis","servingSizeGrams","calories","protein","carbs","fat","fiber","sugar","sodium","potassium","calcium","iron","vitaminC","water","barcode","dataSourceType","dataSourceName","imageUrl");
    private static final Set<String> NUMBERS=Set.of("servingSizeGrams","calories","protein","carbs","fat","fiber","sugar","sodium","potassium","calcium","iron","vitaminC","water");
    private static final String DUPLICATE_WARNING="Có thể trùng dữ liệu; kiểm tra trước khi thêm mới";
    public List<String> columns(String kind){checkKind(kind);return "FOOD".equals(kind)?FOOD:EXERCISE;}
    private void checkKind(String kind){if(!Set.of("FOOD","EXERCISE").contains(kind))throw new IllegalArgumentException("Loại kho không hợp lệ");}
    private void admin(User actor){if(actor==null||!"ADMIN".equals(actor.getRole())||!Boolean.TRUE.equals(actor.getActive()))throw new ResponseStatusException(HttpStatus.FORBIDDEN,"Chỉ quản trị viên đang hoạt động được nhập kho");}
    @Transactional
    public Batch preview(User actor,String kind,byte[] bytes,String filename,Map<String,String> mapping){
        admin(actor);var cols=columns(kind);var table=CatalogTableCodec.read(bytes,filename);if(table.size()<2)throw new IllegalArgumentException("Cần tiêu đề và ít nhất một dòng dữ liệu");
        List<String> headers=table.getFirst().stream().map(String::trim).map(h->mapping.getOrDefault(h,h)).toList();
        var mappedHeaders=headers.stream().filter(h->!"__IGNORE__".equals(h)).toList();
        if(new HashSet<>(mappedHeaders).size()!=mappedHeaders.size())throw new IllegalArgumentException("Không ánh xạ nhiều cột vào cùng một trường");
        List<String> unknown=mappedHeaders.stream().filter(h->!cols.contains(h)).toList();if(!unknown.isEmpty())throw new IllegalArgumentException("Cột chưa được ánh xạ: "+String.join(", ",unknown)+". Hãy ánh xạ hoặc chọn bỏ qua rõ ràng.");
        List<Row> rows=new ArrayList<>();Set<String> seen=new HashSet<>();Set<String> seenIds=new HashSet<>();
        var index=duplicateIndex(kind);var existingKeys=index.keys();var existingBarcodes=index.barcodes();
        for(int i=1;i<table.size();i++){
            Map<String,String> values=new LinkedHashMap<>();for(int j=0;j<headers.size();j++){String h=headers.get(j);if(cols.contains(h))values.put(h,j<table.get(i).size()?table.get(i).get(j).trim():"");}
            List<String> errors=new ArrayList<>(),warnings=new ArrayList<>();String id=values.getOrDefault("id","");Map<String,String> before=new LinkedHashMap<>();
            if(!id.isBlank()) {if(!seenIds.add(id))errors.add("ID xuất hiện nhiều lần trong file");var target=find(id,kind);if(target==null)errors.add("ID không tồn tại");else {before=snapshot(target,kind);if(!eligible(target))errors.add("Chỉ cập nhật bản ghi đang hoạt động và đã duyệt");}}
            Map<String,String> after=Map.of();
            try{after=requestValues(request(kind,values,before,List.of(),!id.isBlank()),kind);}catch(IllegalArgumentException e){errors.add(e.getMessage());}
            if ("FOOD".equals(kind) && errors.isEmpty()) {
                double kcal = Double.parseDouble(after.get("calories"));
                double estimate = 4 * Double.parseDouble(after.get("protein"))
                        + 4 * Double.parseDouble(after.get("carbs")) + 9 * Double.parseDouble(after.get("fat"));
                if (Math.abs(kcal - estimate) > Math.max(30, estimate * 0.2)) {
                    warnings.add("Năng lượng lệch đáng kể so với 4×đạm + 4×carb + 9×béo; kiểm tra nhãn và khẩu phần (chỉ là cảnh báo)");
                }
            }
            Map<String,String> duplicateValues=new LinkedHashMap<>(before);duplicateValues.putAll(after.isEmpty()?values:after);
            String canonical=key(duplicateValues,kind),barcode=duplicateValues.getOrDefault("barcode","");
            boolean duplicate=!seen.add(canonical)||existingKeys.getOrDefault(canonical,Set.of()).stream().anyMatch(other->!other.equals(id))||(!barcode.isBlank()&&existingBarcodes.getOrDefault(barcode,Set.of()).stream().anyMatch(other->!other.equals(id)));
            if(duplicate)warnings.add(DUPLICATE_WARNING);
            rows.add(new Row(i+1,values,before,errors,warnings,!errors.isEmpty()||duplicate||!id.isBlank()?"SKIP":"CREATE",null,after));
        }
        var entity=new CatalogImportBatch();entity.setId(UUID.randomUUID().toString());entity.setActorId(actor.getId());entity.setKind(kind);entity.setCreatedAt(LocalDateTime.now());entity.setSourceDigest(digestBytes(bytes));entity.setSnapshot(json.writeValueAsString(rows));batches.save(entity);return response(entity);
    }
    @Transactional
    public Batch commit(User actor,String id,Commit input){
        admin(actor);if(input==null||input.selections()==null||input.selections().size()>500)throw new IllegalArgumentException("Chọn tối đa 500 dòng");
        var batch=batches.locked(id,actor.getId()).orElseThrow(()->new ResponseStatusException(HttpStatus.NOT_FOUND));
        String digest=digest(json.writeValueAsString(input));
        if(batch.getCommittedAt()!=null){if(!digest.equals(batch.getCommitDigest()))throw new ResponseStatusException(HttpStatus.CONFLICT,"Lô này đã nhập với lựa chọn khác");return response(batch);}
        if(batch.getCreatedAt().isBefore(LocalDateTime.now().minusHours(24)))throw new IllegalArgumentException("Bản xem trước đã hết hạn; hãy tạo lại");
        List<Row> original=read(batch);Map<Integer,Selection> selections=new HashMap<>();for(var s:input.selections()){if(s==null||s.action()==null||!Set.of("CREATE","UPDATE","SKIP").contains(s.action())||selections.put(s.number(),s)!=null)throw new IllegalArgumentException("Lựa chọn dòng không hợp lệ");if(original.stream().noneMatch(r->r.number()==s.number()))throw new IllegalArgumentException("Dòng không thuộc lô nhập");}
        var currentIndex=selections.values().stream().anyMatch(s->"CREATE".equals(s.action()))?duplicateIndex(batch.getKind()):new DuplicateIndex(Map.of(),Map.of());
        List<Row> result=new ArrayList<>();
        for(var row:original){var s=selections.getOrDefault(row.number(),new Selection(row.number(),"SKIP",List.of()));if("SKIP".equals(s.action())){result.add(new Row(row.number(),row.values(),row.before(),row.errors(),row.warnings(),"SKIP",null,row.after()));continue;}
            if(!row.errors().isEmpty())throw new IllegalArgumentException("Dòng "+row.number()+" còn lỗi");
            String targetId=row.values().getOrDefault("id","");boolean update="UPDATE".equals(s.action());if(update==targetId.isBlank())throw new IllegalArgumentException("Cập nhật cần ID, thêm mới phải để trống ID");
            if(update){Object target=find(targetId,batch.getKind());if(target==null)throw new ResponseStatusException(HttpStatus.CONFLICT,"Bản ghi đã bị xóa");em.lock(target,LockModeType.PESSIMISTIC_WRITE);em.refresh(target);if(!eligible(target)||!snapshot(target,batch.getKind()).equals(row.before()))throw new ResponseStatusException(HttpStatus.CONFLICT,"Dữ liệu đã thay đổi; hãy xem trước lại");}
            Object request=request(batch.getKind(),row.values(),row.before(),s.clearFields()==null?List.of():s.clearFields(),update);
            if(!update&&!row.warnings().contains(DUPLICATE_WARNING)){
                var after=requestValues(request,batch.getKind());String barcode=after.getOrDefault("barcode","");
                if(!currentIndex.keys().getOrDefault(key(after,batch.getKind()),Set.of()).isEmpty()||(!barcode.isBlank()&&!currentIndex.barcodes().getOrDefault(barcode,Set.of()).isEmpty()))throw new ResponseStatusException(HttpStatus.CONFLICT,"Dữ liệu trùng mới xuất hiện sau bản xem trước; hãy xem trước lại để xác nhận");
            }
            String resultId;
            if("FOOD".equals(batch.getKind())){resultId=update?foodService.update(targetId,(UpdateFoodRequest)request).getId():foodService.create((CreateFoodRequest)request).getId();}
            else{resultId=update?exerciseService.update(targetId,(UpdateExerciseRequest)request).getId():exerciseService.create((CreateExerciseRequest)request).getId();}
            result.add(new Row(row.number(),row.values(),row.before(),List.of(),row.warnings(),s.action(),resultId,requestValues(request,batch.getKind())));
        }
        batch.setSnapshot(json.writeValueAsString(result));batch.setCommittedAt(LocalDateTime.now());batch.setCommitDigest(digest);batches.save(batch);em.flush();return response(batch);
    }
    @Transactional(readOnly=true) public List<BatchSummary> history(User actor,String kind){admin(actor);checkKind(kind);return batches.findTop30ByActorIdAndKindOrderByCreatedAtDesc(actor.getId(),kind).stream().map(b->{var rows=read(b);return new BatchSummary(b.getId(),b.getKind(),b.getCreatedAt(),b.getCommittedAt(),rows.size(),rows.stream().filter(r->r.resultId()!=null).count(),rows.stream().filter(r->!r.errors().isEmpty()).count());}).toList();}
    @Transactional(readOnly=true) public List<List<String>> export(User actor,String kind){
        admin(actor);var columns=columns(kind);List<List<String>> output=new ArrayList<>();output.add(columns);
        for(int offset=0;;offset+=500){var records=lookup.exportRows(kind,columns,offset,500);for(var record:records){List<String> line=new ArrayList<>();for(String column:columns)line.add(record.getOrDefault(column,""));output.add(line);}if(records.size()<500)break;}return output;
    }
    @Transactional(readOnly=true) public String errors(User actor,String id){admin(actor);var b=batches.findById(id).filter(v->v.getActorId().equals(actor.getId())).orElseThrow(()->new ResponseStatusException(HttpStatus.NOT_FOUND));List<List<String>> output=new ArrayList<>();List<String> head=new ArrayList<>(columns(b.getKind()));head.add("errors");output.add(head);for(var r:read(b)){if(!r.errors().isEmpty()){List<String> line=new ArrayList<>();for(String c:columns(b.getKind()))line.add(r.values().getOrDefault(c,""));line.add(String.join("; ",r.errors()));output.add(line);}}return CatalogTableCodec.csv(output);}
    private Object request(String kind,Map<String,String> values,Map<String,String> before,List<String> clears,boolean update){
        Map<String,String> merged=new LinkedHashMap<>(before);for(var e:values.entrySet())if(!e.getValue().isBlank())merged.put(e.getKey(),e.getValue());
        if("EXERCISE".equals(kind)){
            merged.computeIfPresent("muscleGroup",(k,v)->com.fittrack.common.catalog.CatalogText.muscle(v));
            merged.computeIfPresent("equipment",(k,v)->com.fittrack.common.catalog.CatalogText.equipment(v));
        }
        Set<String> nullable="FOOD".equals(kind)?Set.of("fiber","sugar","sodium","potassium","calcium","iron","vitaminC","water","barcode","dataSourceName","imageUrl"):Set.of("description","imageUrl");
        for(String clear:clears){if(clear==null||!nullable.contains(clear))throw new IllegalArgumentException("Không được xóa trường "+clear);merged.put(clear,"");}
        List<String> required="FOOD".equals(kind)?List.of("name","unit","calories","protein","carbs","fat"):List.of("name","muscleGroup","equipment");
        for(String field:required)if(merged.getOrDefault(field,"").isBlank())throw new IllegalArgumentException("Thiếu "+field);
        String image=values.getOrDefault("imageUrl","");if(!image.isBlank()){try{var uri=java.net.URI.create(image);if(!"https".equalsIgnoreCase(uri.getScheme())||uri.getHost()==null||uri.getUserInfo()!=null)throw new IllegalArgumentException();}catch(Exception e){throw new IllegalArgumentException("Ảnh phải là URL HTTPS hợp lệ");}media.storeNew(image,"catalog-import","preview");}
        Map<String,Object> payload=new LinkedHashMap<>();for(String col:columns(kind)){if(Set.of("id","basis").contains(col))continue;String val=merged.get(col);if(NUMBERS.contains(col)){if(val==null||val.isBlank()){payload.put(col,null);continue;}double number;try{number=Double.parseDouble(val);}catch(Exception e){throw new IllegalArgumentException(col+" phải là số");}if(!Double.isFinite(number)||number<0||("servingSizeGrams".equals(col)&&number==0))throw new IllegalArgumentException(col+" phải hữu hạn và không âm (khẩu phần > 0)");payload.put(col,number);}else payload.put(col,val==null||val.isBlank()?null:val);}
        if("FOOD".equals(kind)){
            String basis=values.getOrDefault("basis","");if(!Set.of("PER_SERVING","PER_100G").contains(basis))throw new IllegalArgumentException("basis phải là PER_SERVING hoặc PER_100G");
            if("PER_100G".equals(basis)){Object weight=payload.get("servingSizeGrams");if(!(weight instanceof Double grams))throw new IllegalArgumentException("PER_100G cần servingSizeGrams để quy đổi khẩu phần");for(String n:NUMBERS)if(!"servingSizeGrams".equals(n)&&!clears.contains(n)&&values.containsKey(n)&&!values.get(n).isBlank()){Double converted=(Double)payload.get(n)*(grams/100);if(!Double.isFinite(converted))throw new IllegalArgumentException(n+" vượt giới hạn số sau quy đổi");payload.put(n,converted);}}
            String source=(String)payload.get("dataSourceType");if(source!=null&&!Set.of("VERIFIED_DATABASE","PRODUCT_LABEL","RECIPE_CALCULATED","COMMUNITY","ESTIMATED").contains(source))throw new IllegalArgumentException("dataSourceType không hợp lệ");
            String barcode=(String)payload.get("barcode");if(barcode!=null&&!barcode.matches("[0-9A-Za-z-]{4,80}"))throw new IllegalArgumentException("barcode gồm 4–80 chữ, số hoặc dấu gạch ngang");
        }
        if(update && image.isBlank() && !clears.contains("imageUrl") && !before.getOrDefault("imageUrl","").isBlank())payload.put("imageUrl","FOOD".equals(kind)?com.fittrack.common.media.ImageReferences.foodPath(before.get("id")):com.fittrack.common.media.ImageReferences.exercisePath(before.get("id")));
        if(clears.contains("dataSourceName"))payload.put("dataSourceName","");
        Class<?> type="FOOD".equals(kind)?update?UpdateFoodRequest.class:CreateFoodRequest.class:update?UpdateExerciseRequest.class:CreateExerciseRequest.class;
        Object dto=json.convertValue(payload,type);var violations=validator.validate(dto);if(!violations.isEmpty())throw new IllegalArgumentException(violations.iterator().next().getPropertyPath()+": "+violations.iterator().next().getMessage());return dto;
    }
    private Object find(String id,String kind){return "FOOD".equals(kind)?foods.findById(id).orElse(null):exercises.findById(id).orElse(null);}
    private boolean eligible(Object obj){var b=new BeanWrapperImpl(obj);return Boolean.TRUE.equals(b.getPropertyValue("active"))&&"APPROVED".equals(b.getPropertyValue("approvalStatus"));}
    private Map<String,String> snapshot(Object obj,String kind){Map<String,String> result=new LinkedHashMap<>();var b=new BeanWrapperImpl(obj);for(String c:columns(kind)){if("basis".equals(c)){result.put(c,"PER_SERVING");continue;}Object value=b.getPropertyValue(c);String text=value==null?"":String.valueOf(value);if("imageUrl".equals(c)){result.put("_imageDigest",digest(text));if(text.startsWith("data:"))text="FOOD".equals(kind)?com.fittrack.common.media.ImageReferences.foodPath((String)b.getPropertyValue("id")):com.fittrack.common.media.ImageReferences.exercisePath((String)b.getPropertyValue("id"));}result.put(c,text);}return result;}
    private Map<String,String> requestValues(Object dto,String kind){Map<String,String> output=new LinkedHashMap<>();var bean=new BeanWrapperImpl(dto);for(String col:columns(kind)){if("basis".equals(col)){output.put(col,"PER_SERVING");continue;}if("id".equals(col))continue;Object value=bean.getPropertyValue(col);output.put(col,value==null?"":String.valueOf(value));}return output;}
    private String key(Map<String,String> v,String kind){
        String name=canonicalText(v.get("name"));
        if("FOOD".equals(kind)){String weight=v.getOrDefault("servingSizeGrams","").trim();if(!weight.isBlank())try{weight=new java.math.BigDecimal(weight).stripTrailingZeros().toPlainString();}catch(NumberFormatException ignored){}return name+"|"+canonicalText(v.get("unit"))+"|"+weight;}
        String muscle=com.fittrack.common.catalog.CatalogText.muscle(canonicalText(v.get("muscleGroup")));
        String equipment=com.fittrack.common.catalog.CatalogText.equipment(canonicalText(v.get("equipment")));
        return name+"|"+canonicalText(muscle)+"|"+canonicalText(equipment);
    }
    private String canonicalText(String value){return com.fittrack.common.catalog.CatalogText.normalize(java.text.Normalizer.normalize(value==null?"":value,java.text.Normalizer.Form.NFKC).replaceAll("(?U)\\s+"," "));}
    private record DuplicateIndex(Map<String,Set<String>> keys,Map<String,Set<String>> barcodes) {}
    private DuplicateIndex duplicateIndex(String kind){
        Map<String,Set<String>> keys=new HashMap<>(),barcodes=new HashMap<>();
        for(int offset=0;;offset+=1000){var projected=lookup.duplicateRows(kind,offset,1000);for(var item:projected){keys.computeIfAbsent(key(item,kind),k->new HashSet<>()).add(item.get("id"));String barcode=item.getOrDefault("barcode","");if(!barcode.isBlank())barcodes.computeIfAbsent(barcode,k->new HashSet<>()).add(item.get("id"));}if(projected.size()<1000)break;}
        return new DuplicateIndex(keys,barcodes);
    }
    private List<Row> read(CatalogImportBatch b){return Arrays.asList(json.readValue(b.getSnapshot(),Row[].class));}
    private Batch response(CatalogImportBatch b){return new Batch(b.getId(),b.getKind(),b.getCreatedAt(),b.getCommittedAt(),read(b));}
    private String digest(String value){try{return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(value.getBytes(StandardCharsets.UTF_8)));}catch(Exception e){throw new IllegalStateException(e);}}
    private String digestBytes(byte[] value){try{return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(value));}catch(Exception e){throw new IllegalStateException(e);}}
}
