package com.fittrack.nutrition.purchaseprices;
import com.fittrack.common.dto.PageResponse;
import com.fittrack.user.entity.User;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import java.time.LocalDate;
import static com.fittrack.nutrition.purchaseprices.PurchasePriceDtos.*;
@RestController @RequestMapping("/api/nutrition/purchase-prices") @RequiredArgsConstructor
public class PurchasePriceController {
 private final PurchasePriceService service;private User user(Authentication a){return (User)a.getPrincipal();}
 @GetMapping public PageResponse<Price> list(Authentication a,@RequestParam(defaultValue="true")boolean active,@RequestParam(required=false)String foodId,@RequestParam(defaultValue="0")int page,@RequestParam(defaultValue="20")int size){return service.list(user(a),active,foodId,page,size);}
 @PostMapping public Price create(Authentication a,@RequestBody @Valid Input r){return service.save(user(a),null,r);}
 @PutMapping("/{id}") public Price edit(Authentication a,@PathVariable String id,@RequestBody @Valid Input r){return service.save(user(a),id,r);}
 @DeleteMapping("/{id}") public void delete(Authentication a,@PathVariable String id,@RequestParam long version){service.archive(user(a),id,version);}
 @GetMapping("/week-cost") public WeekCost cost(Authentication a,@RequestParam LocalDate week,@RequestParam LocalDate referenceDate){return service.cost(user(a),week,referenceDate);}
}
