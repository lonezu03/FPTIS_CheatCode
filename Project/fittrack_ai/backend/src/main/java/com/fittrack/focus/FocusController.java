package com.fittrack.focus;
import com.fittrack.user.entity.User;
import com.fittrack.common.dto.PageResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import java.time.LocalDate;
@RestController @RequestMapping("/api/todos/focus") @RequiredArgsConstructor
public class FocusController {
 private final FocusService service;
 @GetMapping("/active") public FocusDtos.View active(@AuthenticationPrincipal User user){return service.active(user);}
 @GetMapping("/{id}") public FocusDtos.View detail(@AuthenticationPrincipal User user,@PathVariable String id){return service.detail(user,id);}
 @GetMapping public PageResponse<FocusDtos.View> history(@AuthenticationPrincipal User user,@RequestParam LocalDate from,@RequestParam LocalDate to,@RequestParam(defaultValue="0")int page,@RequestParam(defaultValue="15")int size){return service.history(user,from,to,page,size);}
 @PostMapping public FocusDtos.View start(@AuthenticationPrincipal User user,@Valid @RequestBody FocusDtos.Start input){return service.start(user,input);}
 @PostMapping("/{id}/actions") public FocusDtos.View command(@AuthenticationPrincipal User user,@PathVariable String id,@Valid @RequestBody FocusDtos.Command input){return service.command(user,id,input);}
}
