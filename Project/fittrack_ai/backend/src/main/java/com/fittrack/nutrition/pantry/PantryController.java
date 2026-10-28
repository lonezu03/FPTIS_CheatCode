package com.fittrack.nutrition.pantry;
import com.fittrack.common.dto.PageResponse;
import com.fittrack.user.entity.User;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import java.util.List;
import static com.fittrack.nutrition.pantry.PantryDtos.*;
@RestController @RequestMapping("/api/nutrition/pantry") @RequiredArgsConstructor
public class PantryController {
 private final PantryService service;private User user(Authentication a){return (User)a.getPrincipal();}
 @GetMapping public PageResponse<Batch> list(Authentication a,@RequestParam(defaultValue="true")boolean active,@RequestParam(defaultValue="0")int page,@RequestParam(defaultValue="20")int size){return service.list(user(a),active,page,size);}
 @PostMapping public Batch create(Authentication a,@RequestBody @Valid Create r){return service.create(user(a),r);}
 @PutMapping("/{id}") public Batch edit(Authentication a,@PathVariable String id,@RequestBody @Valid Edit r){return service.edit(user(a),id,r);}
 @PostMapping("/{id}/operations") public Batch operate(Authentication a,@PathVariable String id,@RequestBody @Valid Operate r){return service.operate(user(a),id,r);}
 @GetMapping("/{id}/operations") public PageResponse<Operation> history(Authentication a,@PathVariable String id,@RequestParam(defaultValue="0")int page){return service.history(user(a),id,page);}
 @GetMapping("/suggestions") public List<Suggestion> suggestions(Authentication a){return service.suggestions(user(a));}
}
