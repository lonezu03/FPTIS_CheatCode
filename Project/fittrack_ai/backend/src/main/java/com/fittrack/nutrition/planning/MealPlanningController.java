package com.fittrack.nutrition.planning;

import com.fittrack.common.dto.PageResponse;
import com.fittrack.user.entity.User;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import java.time.LocalDate;
import java.util.Map;
import static com.fittrack.nutrition.planning.PlanningDtos.*;

@RestController @RequestMapping("/api/nutrition/planning") @RequiredArgsConstructor
public class MealPlanningController {
    private final MealPlanningService service;
    private User user(Authentication auth) {return (User)auth.getPrincipal();}
    @GetMapping("/summary") public WeekSummary summary(Authentication auth,@RequestParam LocalDate week){return service.summary(user(auth),week);}
    @GetMapping("/meals") public PageResponse<MealResponse> list(Authentication auth,@RequestParam LocalDate from,@RequestParam LocalDate to,
            @RequestParam(defaultValue="0") int page,@RequestParam(defaultValue="30") int size) {return service.list(user(auth),from,to,page,size);}
    @PostMapping("/meals") public MealResponse create(Authentication auth,@Valid @RequestBody MealRequest r){return service.create(user(auth),r);}
    @PutMapping("/meals/{id}") public MealResponse update(Authentication auth,@PathVariable String id,@Valid @RequestBody MealRequest r){return service.update(user(auth),id,r);}
    @DeleteMapping("/meals/{id}") public void delete(Authentication auth,@PathVariable String id,@RequestParam long version){service.delete(user(auth),id,version);}
    @PostMapping("/meals/{id}/log") public LogResult log(Authentication auth,@PathVariable String id,@Valid @RequestBody VersionRequest r){return service.log(user(auth),id,r);}
    @PostMapping("/copy-week") public Map<String,Integer> copy(Authentication auth,@Valid @RequestBody CopyWeekRequest r){return Map.of("copiedCount",service.copyWeek(user(auth),r));}
    @GetMapping("/groceries") public GroceryResponse groceries(Authentication auth,@RequestParam LocalDate week){return service.groceryList(user(auth),week);}
    @PostMapping("/groceries/regenerate") public GroceryResponse regenerate(Authentication auth,@Valid @RequestBody GroceryRefreshRequest r){return service.regenerate(user(auth),r);}
    @PostMapping("/groceries/items") public GroceryResponse manual(Authentication auth,@Valid @RequestBody GroceryManualRequest r){return service.addManual(user(auth),r);}
    @PutMapping("/groceries/items/{id}") public GroceryResponse check(Authentication auth,@PathVariable String id,@Valid @RequestBody GroceryCheckRequest r){return service.check(user(auth),id,r,false);}
    @DeleteMapping("/groceries/items/{id}") public GroceryResponse remove(Authentication auth,@PathVariable String id,@RequestParam LocalDate week,@RequestParam long version){return service.check(user(auth),id,new GroceryCheckRequest(week,version,false),true);}
}
