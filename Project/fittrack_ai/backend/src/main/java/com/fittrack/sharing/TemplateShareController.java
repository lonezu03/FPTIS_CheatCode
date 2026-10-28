package com.fittrack.sharing;

import com.fittrack.user.entity.User;
import com.fittrack.common.dto.PageResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController @RequestMapping("/api/template-shares") @RequiredArgsConstructor
public class TemplateShareController {
    private final TemplateShareService service;
    @GetMapping public PageResponse<TemplateShareService.View> list(@AuthenticationPrincipal User user,
            @RequestParam(defaultValue="true") boolean inbox,@RequestParam(defaultValue="0") int page,@RequestParam(defaultValue="15") int size){return service.list(user,inbox,page,size);}
    @PostMapping public TemplateShareService.View create(@AuthenticationPrincipal User user,@Valid @RequestBody TemplateShareService.Create input){return service.create(user,input);}
    @GetMapping("/{id}") public TemplateShareService.Preview preview(@AuthenticationPrincipal User user,@PathVariable String id){return service.preview(user,id);}
    @PostMapping("/{id}/accept") public TemplateShareService.CopyResult accept(@AuthenticationPrincipal User user,@PathVariable String id,@RequestBody(required=false) TemplateShareService.Accept input){return service.accept(user,id,input);}
    @DeleteMapping("/{id}") public TemplateShareService.View revoke(@AuthenticationPrincipal User user,@PathVariable String id,@RequestParam long version){return service.revoke(user,id,version);}
}
