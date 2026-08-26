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
import com.fittrack.common.dto.PageResponse;

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

    @GetMapping("/wallet/transactions/page")
    public PageResponse<WalletTransactionResponse> getWalletTransactionsPage(
            Authentication authentication,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size
    ) {
        return lunchService.getWalletTransactionsPage(
                currentUser(authentication), page, size
        );
    }

    @GetMapping("/orders/history")
    public List<OrderResponse> getOrderHistory(Authentication authentication) {
        return lunchService.getOrderHistory(currentUser(authentication));
    }

    @GetMapping("/orders/history/page")
    public PageResponse<OrderResponse> getOrderHistoryPage(
            Authentication authentication,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size
    ) {
        return lunchService.getOrderHistoryPage(
                currentUser(authentication), page, size
        );
    }

    @PostMapping("/orders")
    @ResponseStatus(HttpStatus.CREATED)
    public OrderResponse createOrder(
            Authentication authentication,
            @Valid @RequestBody CreateOrderRequest request
    ) {
        return lunchService.createOrder(currentUser(authentication), request);
    }

    @PostMapping("/orders/batch")
    @ResponseStatus(HttpStatus.CREATED)
    public OrderBatchResponse createOrderBatch(
            Authentication authentication,
            @Valid @RequestBody CreateOrderBatchRequest request
    ) {
        return lunchService.createOrderBatch(currentUser(authentication), request);
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

    @GetMapping("/payment-requests/mine/page")
    public PageResponse<PaymentRequestResponse> getMyPaymentRequestsPage(
            Authentication authentication,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size
    ) {
        return paymentService.getMinePage(currentUser(authentication), page, size);
    }

    @GetMapping("/notifications")
    public NotificationListResponse getNotifications(Authentication authentication) {
        return notificationService.getMine(currentUser(authentication));
    }

    @GetMapping("/notifications/page")
    public PageResponse<NotificationResponse> getNotificationsPage(
            Authentication authentication,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size
    ) {
        return notificationService.getMinePage(currentUser(authentication), page, size);
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
