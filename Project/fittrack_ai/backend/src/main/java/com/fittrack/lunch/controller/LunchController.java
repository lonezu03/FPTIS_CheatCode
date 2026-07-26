package com.fittrack.lunch.controller;

import com.fittrack.lunch.dto.LunchDtos.*;
import com.fittrack.lunch.service.LunchService;
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

    private User currentUser(Authentication authentication) {
        return (User) authentication.getPrincipal();
    }
}
