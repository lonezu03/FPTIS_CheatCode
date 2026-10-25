package com.fittrack.catalogimport;

import com.fittrack.user.entity.User;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.*;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import tools.jackson.databind.ObjectMapper;
import java.nio.charset.StandardCharsets;
import java.util.*;

@RestController @RequestMapping("/api/catalog-imports") @RequiredArgsConstructor
@PreAuthorize("hasRole('ADMIN')")
public class CatalogImportController {
    private final CatalogImportService service;
    private final ObjectMapper json;
    @GetMapping("/{kind}/export") public ResponseEntity<byte[]> export(@AuthenticationPrincipal User actor,@PathVariable String kind,@RequestParam(defaultValue="csv") String format){
        var rows=service.export(actor,kind);boolean xlsx="xlsx".equals(format);return ResponseEntity.ok().header(HttpHeaders.CONTENT_DISPOSITION,"attachment; filename=\""+kind.toLowerCase()+"-export."+(xlsx?"xlsx":"csv")+"\"").contentType(MediaType.parseMediaType(xlsx?"application/vnd.openxmlformats-officedocument.spreadsheetml.sheet":"text/csv;charset=UTF-8")).body(xlsx?CatalogTableCodec.workbook(rows):CatalogTableCodec.csv(rows).getBytes(StandardCharsets.UTF_8));
    }
    @GetMapping("/{kind}/template")
    public ResponseEntity<byte[]> template(@PathVariable String kind,@RequestParam(defaultValue="csv") String format){
        List<List<String>> rows=List.of(service.columns(kind));boolean xlsx="xlsx".equals(format);
        return ResponseEntity.ok().header(HttpHeaders.CONTENT_DISPOSITION,"attachment; filename=\""+kind.toLowerCase()+"-template."+(xlsx?"xlsx":"csv")+"\"")
                .contentType(MediaType.parseMediaType(xlsx?"application/vnd.openxmlformats-officedocument.spreadsheetml.sheet":"text/csv;charset=UTF-8"))
                .body(xlsx?CatalogTableCodec.workbook(rows):CatalogTableCodec.csv(rows).getBytes(StandardCharsets.UTF_8));
    }
    @PostMapping(value="/{kind}/preview",consumes=MediaType.MULTIPART_FORM_DATA_VALUE)
    public CatalogImportService.Batch preview(@AuthenticationPrincipal User actor,@PathVariable String kind,
            @RequestParam(required=false) MultipartFile file,@RequestParam(required=false) String text,
            @RequestParam(defaultValue="{}") String mapping) throws java.io.IOException {
        if(file!=null&&file.getSize()>2_000_000)throw new IllegalArgumentException("File tối đa 2 MB");
        if(file==null&&(text==null||text.isBlank()))throw new IllegalArgumentException("Chọn file hoặc dán bảng dữ liệu");
        Map<String,String> mapped=new LinkedHashMap<>();
        try {Object parsed=json.readValue(mapping,Object.class);if(!(parsed instanceof Map<?,?> raw))throw new IllegalArgumentException();for(var e:raw.entrySet()){if(!(e.getKey() instanceof String key)||!(e.getValue() instanceof String value))throw new IllegalArgumentException();mapped.put(key,value);}}
        catch(Exception e){throw new IllegalArgumentException("Ánh xạ cột phải là đối tượng tên cột → tên trường");}
        return service.preview(actor,kind,file==null?text.getBytes(StandardCharsets.UTF_8):file.getBytes(),file==null?"paste.tsv":file.getOriginalFilename(),mapped);
    }
    @PostMapping("/{id}/commit") public CatalogImportService.Batch commit(@AuthenticationPrincipal User actor,@PathVariable String id,@Valid @RequestBody CatalogImportService.Commit request){return service.commit(actor,id,request);}
    @GetMapping public List<CatalogImportService.BatchSummary> history(@AuthenticationPrincipal User actor,@RequestParam String kind){return service.history(actor,kind);}
    @GetMapping("/{id}/errors.csv") public ResponseEntity<String> errors(@AuthenticationPrincipal User actor,@PathVariable String id){return ResponseEntity.ok().header(HttpHeaders.CONTENT_DISPOSITION,"attachment; filename=\"import-errors.csv\"").contentType(MediaType.parseMediaType("text/csv;charset=UTF-8")).body(service.errors(actor,id));}
}
