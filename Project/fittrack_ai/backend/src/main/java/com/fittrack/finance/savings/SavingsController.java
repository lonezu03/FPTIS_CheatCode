package com.fittrack.finance.savings;
import com.fittrack.finance.savings.SavingsDtos.*;
import com.fittrack.user.entity.User;
import com.fittrack.common.dto.PageResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
@RestController @RequestMapping("/api/finance/savings") @RequiredArgsConstructor
public class SavingsController {
 private final SavingsService service;
 @GetMapping public PageResponse<Response> list(@AuthenticationPrincipal User u,@RequestParam(defaultValue="false")boolean archived,@RequestParam(defaultValue="0")int page,@RequestParam(defaultValue="15")int size){return service.list(u,archived,page,size);}
 @PostMapping public Response create(@AuthenticationPrincipal User u,@RequestBody Request r){return service.save(u,null,r);}
 @PatchMapping("/{id}") public Response edit(@AuthenticationPrincipal User u,@PathVariable String id,@RequestBody Request r){return service.save(u,id,r);}
 @DeleteMapping("/{id}") public void archive(@AuthenticationPrincipal User u,@PathVariable String id,@RequestParam Long version){service.archive(u,id,version);}
 @GetMapping("/{id}/operations") public PageResponse<OperationResponse> history(@AuthenticationPrincipal User u,@PathVariable String id,@RequestParam(defaultValue="0")int page,@RequestParam(defaultValue="15")int size){return service.history(u,id,page,size);}
 @PostMapping("/{id}/operations") public OperationResponse record(@AuthenticationPrincipal User u,@PathVariable String id,@RequestBody OperationRequest r){return service.record(u,id,r);}
}
