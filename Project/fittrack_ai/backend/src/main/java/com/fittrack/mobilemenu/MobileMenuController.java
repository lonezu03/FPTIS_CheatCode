package com.fittrack.mobilemenu;

import com.fittrack.user.entity.User;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.*;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController @RequiredArgsConstructor
public class MobileMenuController {
    private final MobileMenuService service;
    @GetMapping("/api/mobile-menu")
    public ResponseEntity<MobileMenuService.Menu> get() {
        return ResponseEntity.ok().cacheControl(CacheControl.noStore()).body(service.get());
    }
    // SecurityConfig protects /api/admin/** independently of method security.
    @PutMapping("/api/admin/mobile-menu")
    public MobileMenuService.Menu update(@Valid @RequestBody MobileMenuService.Menu request, Authentication auth) {
        String actor = auth.getPrincipal() instanceof User user ? user.getId() : auth.getName();
        return service.update(request, actor);
    }
}
