package com.fittrack.lunch.dto;

import com.fittrack.lunch.entity.LunchSelectionType;
import jakarta.validation.constraints.*;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

public final class LunchDtos {

    private LunchDtos() {
    }

    public record MenuItemResponse(
            String id,
            String name,
            String type,
            Integer sortOrder
    ) {
    }

    public record MenuResponse(
            String id,
            LocalDate menuDate,
            String orderLabel,
            String vendorName,
            LocalDateTime cutoffAt,
            Long price,
            String status,
            boolean summarized,
            boolean acceptingOrders,
            List<MenuItemResponse> regularItems,
            List<MenuItemResponse> specialItems,
            long totalOrders,
            long unpaidOrders
    ) {
    }

    public record PersonResponse(
            String id,
            String fullName,
            String email
    ) {
    }

    public record OrderResponse(
            String id,
            String menuId,
            LocalDate menuDate,
            PersonResponse beneficiary,
            PersonResponse payer,
            PersonResponse orderedBy,
            String selectionType,
            List<MenuItemResponse> items,
            String note,
            String displayText,
            Long price,
            String paymentStatus,
            String status,
            LocalDateTime createdAt
    ) {
    }

    public record TodayResponse(
            MenuResponse menu,
            Long walletBalance,
            OrderResponse myMealOrder,
            List<OrderResponse> ordersPlacedByMe,
            boolean canOrder,
            String blockReason
    ) {
    }

    public record CreateOrderRequest(
            @NotBlank String menuId,
            String beneficiaryUserId,
            @NotNull LunchSelectionType selectionType,
            @NotEmpty List<@NotBlank String> itemIds,
            @Size(max = 500) String note
    ) {
    }

    public record UpdateOrderRequest(
            @NotNull LunchSelectionType selectionType,
            @NotEmpty List<@NotBlank String> itemIds,
            @Size(max = 500) String note
    ) {
    }

    public record ImportMenuRequest(
            @NotNull LocalDate menuDate,
            @Size(max = 255) String orderLabel,
            @Size(max = 255) String vendorName,
            @NotNull LocalDateTime cutoffAt,
            @Positive Long price,
            @NotBlank String rawMenuText
    ) {
    }

    public record TopUpRequest(
            @NotBlank String userId,
            @NotNull @Positive Long amount,
            @Size(max = 500) String note
    ) {
    }

    public record ConfirmExternalPaymentRequest(
            @Size(max = 500) String note
    ) {
    }

    public record MemberResponse(
            String id,
            String fullName,
            String email,
            Long walletBalance,
            long unpaidOrders
    ) {
    }

    public record WalletTransactionResponse(
            String id,
            String type,
            Long amount,
            Long balanceAfter,
            String note,
            LocalDateTime createdAt,
            String relatedOrderId,
            PersonResponse createdBy
    ) {
    }

    public record DishCountResponse(
            String dishName,
            long count
    ) {
    }

    public record SummaryResponse(
            long totalOrders,
            long paidFundOrders,
            long paidExternalOrders,
            long unpaidOrders,
            Long totalAmount,
            String orderText,
            List<DishCountResponse> dishCounts
    ) {
    }
}
