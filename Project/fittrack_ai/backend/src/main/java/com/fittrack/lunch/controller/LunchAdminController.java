package com.fittrack.lunch.controller;

import com.fittrack.lunch.dto.LunchDtos.*;
import com.fittrack.lunch.service.LunchAdminService;
import com.fittrack.user.entity.User;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;

@RestController
@RequestMapping("/api/lunch/admin")
@RequiredArgsConstructor
public class LunchAdminController {

    private final LunchAdminService lunchAdminService;

    @GetMapping("/menus")
    public List<MenuResponse> getMenus(
            @RequestParam(required = false) LocalDate from,
            @RequestParam(required = false) LocalDate to
    ) {
        return lunchAdminService.getMenus(from, to);
    }

    @PostMapping("/menus/import")
    @ResponseStatus(HttpStatus.CREATED)
    public MenuResponse importMenu(
            Authentication authentication,
            @Valid @RequestBody ImportMenuRequest request
    ) {
        return lunchAdminService.importMenu(currentUser(authentication), request);
    }

    @GetMapping("/menus/{id}/orders")
    public List<OrderResponse> getMenuOrders(@PathVariable String id) {
        return lunchAdminService.getMenuOrders(id);
    }

    @PostMapping("/menus/{id}/summarize")
    public SummaryResponse summarizeMenu(
            Authentication authentication,
            @PathVariable String id
    ) {
        return lunchAdminService.summarize(currentUser(authentication), id);
    }

    @PostMapping("/menus/{id}/close")
    public MenuResponse closeMenu(@PathVariable String id) {
        return lunchAdminService.closeMenu(id);
    }

    @PostMapping("/menus/{id}/reopen")
    public MenuResponse reopenMenu(@PathVariable String id) {
        return lunchAdminService.reopenMenu(id);
    }

    @GetMapping("/members")
    public List<MemberResponse> getMembers() {
        return lunchAdminService.getMembers();
    }

    @PostMapping("/funds/top-up")
    @ResponseStatus(HttpStatus.CREATED)
    public WalletTransactionResponse topUp(
            Authentication authentication,
            @Valid @RequestBody TopUpRequest request
    ) {
        return lunchAdminService.topUp(currentUser(authentication), request);
    }

    @PostMapping("/orders/{id}/confirm-external")
    public OrderResponse confirmExternalPayment(
            Authentication authentication,
            @PathVariable String id,
            @Valid @RequestBody(required = false) ConfirmExternalPaymentRequest request
    ) {
        return lunchAdminService.confirmExternalPayment(
                currentUser(authentication),
                id,
                request
        );
    }

    private User currentUser(Authentication authentication) {
        return (User) authentication.getPrincipal();
    }
}
