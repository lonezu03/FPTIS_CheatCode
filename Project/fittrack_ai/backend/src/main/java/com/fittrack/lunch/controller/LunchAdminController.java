package com.fittrack.lunch.controller;

import com.fittrack.lunch.dto.LunchDtos.*;
import com.fittrack.lunch.service.LunchAdminService;
import com.fittrack.lunch.service.LunchPaymentService;
import com.fittrack.user.entity.User;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import com.fittrack.common.dto.PageResponse;

@RestController
@RequestMapping("/api/lunch/admin")
@RequiredArgsConstructor
public class LunchAdminController {

    private final LunchAdminService lunchAdminService;
    private final LunchPaymentService paymentService;

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

    @PutMapping("/menus/{id}")
    public MenuResponse updateMenu(
            Authentication authentication,
            @PathVariable String id,
            @Valid @RequestBody UpdateMenuRequest request
    ) {
        return lunchAdminService.updateMenu(currentUser(authentication), id, request);
    }

    @DeleteMapping("/menus/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deleteMenu(
            Authentication authentication,
            @PathVariable String id
    ) {
        lunchAdminService.deleteMenu(currentUser(authentication), id);
    }

    @PostMapping("/menus/{id}/notify")
    public MenuNotificationResponse notifyMenu(
            Authentication authentication,
            @PathVariable String id
    ) {
        return lunchAdminService.notifyMenu(currentUser(authentication), id);
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

    @PostMapping("/funds/adjust")
    @ResponseStatus(HttpStatus.CREATED)
    public WalletTransactionResponse adjustFund(
            Authentication authentication,
            @Valid @RequestBody FundAdjustmentRequest request
    ) {
        return lunchAdminService.adjustFund(currentUser(authentication), request);
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

    @PutMapping("/menu-items/{id}")
    public MenuItemResponse updateMenuItem(
            @PathVariable String id,
            @Valid @RequestBody UpdateMenuItemRequest request
    ) {
        return lunchAdminService.updateMenuItem(id, request);
    }

    @PutMapping("/payment-settings")
    public PaymentSettingsResponse updatePaymentSettings(
            @Valid @RequestBody UpdatePaymentSettingsRequest request
    ) {
        return paymentService.updateSettings(request);
    }

    @GetMapping("/payment-requests")
    public List<PaymentRequestResponse> getPaymentRequests() {
        return paymentService.getAll();
    }

    @GetMapping("/payment-requests/page")
    public PageResponse<PaymentRequestResponse> getPaymentRequestsPage(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size
    ) {
        return paymentService.getAllPage(page, size);
    }

    @PostMapping("/payment-requests/{id}/approve")
    public PaymentRequestResponse approvePayment(
            Authentication authentication,
            @PathVariable String id,
            @Valid @RequestBody(required = false) ReviewPaymentRequest request
    ) {
        return paymentService.approve(currentUser(authentication), id, request);
    }

    @PostMapping("/payment-requests/{id}/reject")
    public PaymentRequestResponse rejectPayment(
            Authentication authentication,
            @PathVariable String id,
            @Valid @RequestBody(required = false) ReviewPaymentRequest request
    ) {
        return paymentService.reject(currentUser(authentication), id, request);
    }

    private User currentUser(Authentication authentication) {
        return (User) authentication.getPrincipal();
    }
}
