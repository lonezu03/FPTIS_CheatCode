package com.fittrack.lunch.controller;

import com.fittrack.lunch.dto.LunchDtos.*;
import com.fittrack.lunch.service.LunchService;
import com.fittrack.lunch.service.LunchPaymentService;
import com.fittrack.lunch.service.LunchNotificationService;
import com.fittrack.lunch.service.LunchReviewService;
import com.fittrack.user.entity.User;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/lunch")
@RequiredArgsConstructor
public class LunchController {

    private final LunchService lunchService;
    private final LunchPaymentService paymentService;
    private final LunchNotificationService notificationService;
    private final LunchReviewService reviewService;

    @GetMapping("/today")
    public TodayResponse getToday(Authentication authentication) {
        return lunchService.getToday(currentUser(authentication));
    }

    @GetMapping("/people")
    public List<PersonResponse> getPeople(Authentication authentication) {
        return lunchService.getPeople(currentUser(authentication));
    }

    @GetMapping("/wallet/transactions")
    public List<WalletTransactionResponse> getWalletTransactions(
            Authentication authentication
    ) {
        return lunchService.getWalletTransactions(currentUser(authentication));
    }

    @GetMapping("/orders/history")
    public List<OrderResponse> getOrderHistory(Authentication authentication) {
        return lunchService.getOrderHistory(currentUser(authentication));
    }

    @PostMapping("/orders")
    @ResponseStatus(HttpStatus.CREATED)
    public OrderResponse createOrder(
            Authentication authentication,
            @Valid @RequestBody CreateOrderRequest request
    ) {
        return lunchService.createOrder(currentUser(authentication), request);
    }

    @PutMapping("/orders/{id}")
    public OrderResponse updateOrder(
            Authentication authentication,
            @PathVariable String id,
            @Valid @RequestBody UpdateOrderRequest request
    ) {
        return lunchService.updateOrder(currentUser(authentication), id, request);
    }

    @DeleteMapping("/orders/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void cancelOrder(
            Authentication authentication,
            @PathVariable String id
    ) {
        lunchService.cancelOrder(currentUser(authentication), id);
    }

    @PutMapping("/orders/{id}/reviews")
    public DishReviewResponse reviewDish(
            Authentication authentication,
            @PathVariable String id,
            @Valid @RequestBody DishReviewRequest request
    ) {
        return reviewService.review(currentUser(authentication), id, request);
    }

    @GetMapping("/menu-items/{id}/reviews")
    public List<DishReviewResponse> getDishReviews(@PathVariable String id) {
        return reviewService.getDishReviews(id);
    }

    @GetMapping("/payment-settings")
    public PaymentSettingsResponse getPaymentSettings() {
        return paymentService.getSettings();
    }

    @PostMapping("/payment-requests")
    @ResponseStatus(HttpStatus.CREATED)
    public PaymentRequestResponse createPaymentRequest(
            Authentication authentication,
            @Valid @RequestBody CreatePaymentRequest request
    ) {
        return paymentService.create(currentUser(authentication), request);
    }

    @GetMapping("/payment-requests/mine")
    public List<PaymentRequestResponse> getMyPaymentRequests(Authentication authentication) {
        return paymentService.getMine(currentUser(authentication));
    }

    @GetMapping("/notifications")
    public NotificationListResponse getNotifications(Authentication authentication) {
        return notificationService.getMine(currentUser(authentication));
    }

    @PatchMapping("/notifications/{id}/read")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void markNotificationRead(
            Authentication authentication,
            @PathVariable String id
    ) {
        notificationService.markRead(currentUser(authentication), id);
    }

    @PostMapping("/notifications/read-all")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void markAllNotificationsRead(Authentication authentication) {
        notificationService.markAllRead(currentUser(authentication));
    }

    private User currentUser(Authentication authentication) {
        return (User) authentication.getPrincipal();
    }
}
