package com.fittrack.demo.controller;

import com.fittrack.demo.dto.DemoSeedResponse;
import com.fittrack.demo.service.DemoSeedService;
import com.fittrack.user.entity.User;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/demo")
@RequiredArgsConstructor
public class DemoSeedController {

    private final DemoSeedService demoSeedService;

    @PostMapping("/seed")
    public DemoSeedResponse seed(Authentication authentication) {
        User user = (User) authentication.getPrincipal();

        return demoSeedService.seed(user);
    }
}
