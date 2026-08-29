package com.fittrack.lunch.dto;

import com.fittrack.lunch.entity.LunchSelectionType;
import com.fittrack.lunch.entity.LunchPaymentRequestType;
import jakarta.validation.Valid;
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
            Integer sortOrder,
            String imageUrl,
            Double calories,
            Double protein,
            Double carbs,
            Double fat,
            Long unitPrice,
            Double averageRating,
            long reviewCount
    ) {
    }

    public record DishReviewResponse(
            String id,
            String orderId,
            String menuItemId,
            String dishName,
            PersonResponse reviewer,
            Integer rating,
            String comment,
            LocalDateTime createdAt,
            LocalDateTime updatedAt
    ) {
    }

    public record MenuResponse(
            String id,
            LocalDate menuDate,
            String orderLabel,
            String vendorName,
            PersonResponse coordinator,
            LocalDateTime cutoffAt,
            Long price,
            String status,
            boolean summarized,
            boolean acceptingOrders,
            boolean canReplace,
            List<MenuItemResponse> regularItems,
            List<MenuItemResponse> specialItems,
            List<MenuItemResponse> extraItems,
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
            LocalDateTime createdAt,
            List<DishReviewResponse> reviews
    ) {
    }

    public record TodayResponse(
            MenuResponse menu,
            Long walletBalance,
            Long outstandingDebt,
            OrderResponse myMealOrder,
            List<OrderResponse> myMealOrders,
            List<OrderResponse> ordersPlacedByMe,
            boolean canOrder,
            String blockReason,
            List<MenuResponse> menus,
            boolean requiresMenuSelection
    ) {
    }

    public record CreateOrderRequest(
            @NotBlank String menuId,
            String beneficiaryUserId,
            @NotNull LunchSelectionType selectionType,
            @NotEmpty List<@NotBlank String> itemIds,
            List<@NotBlank String> extraItemIds,
            @Size(max = 500) String note
    ) {
        public CreateOrderRequest(
                String menuId,
                String beneficiaryUserId,
                LunchSelectionType selectionType,
                List<String> itemIds,
                String note
        ) {
            this(menuId, beneficiaryUserId, selectionType, itemIds, null, note);
        }
    }

    /**
     * Creates multiple lunch portions in one atomic request.  Each portion keeps
     * its own payment, nutrition log and cancellation lifecycle.
     */
    public record CreateOrderBatchRequest(
            @NotBlank String menuId,
            @NotBlank @Pattern(regexp = "[A-Za-z0-9_-]{8,64}") String clientRequestId,
            @NotEmpty @Size(max = 20) List<@NotNull @Valid OrderPortionRequest> portions
    ) {
    }

    public record OrderPortionRequest(
            String beneficiaryUserId,
            @NotNull LunchSelectionType selectionType,
            @NotEmpty List<@NotBlank String> itemIds,
            List<@NotBlank String> extraItemIds,
            @Size(max = 500) String note
    ) {
        public OrderPortionRequest(
                String beneficiaryUserId,
                LunchSelectionType selectionType,
                List<String> itemIds,
                String note
        ) {
            this(beneficiaryUserId, selectionType, itemIds, null, note);
        }
    }

    public record OrderBatchResponse(
            List<OrderResponse> orders,
            long totalPrice
    ) {
    }

    public record UpdateOrderRequest(
            @NotNull LunchSelectionType selectionType,
            @NotEmpty List<@NotBlank String> itemIds,
            List<@NotBlank String> extraItemIds,
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

    /**
     * Replaces a draft menu's metadata and parsed item list while preserving the
     * menu id.  The service only accepts this before any order exists.
     */
    public record UpdateMenuRequest(
            @NotNull LocalDate menuDate,
            @Size(max = 255) String orderLabel,
            @Size(max = 255) String vendorName,
            @NotNull LocalDateTime cutoffAt,
            @Positive Long price,
            @NotBlank String rawMenuText
    ) {
    }

    public record MenuNotificationResponse(
            String message,
            int recipientCount,
            int emailEligibleCount,
            int emailSentCount,
            int emailFailedCount,
            int emailSkippedCount
    ) {
    }

    public record TopUpRequest(
            @NotBlank String userId,
            @NotNull @Positive Long amount,
            @Size(max = 500) String note
    ) {
    }

    public record FundAdjustmentRequest(
            @NotBlank String userId,
            @NotNull @Positive Long amount,
            @NotNull FundAdjustmentAction action,
            @Size(max = 500) String note
    ) {
    }

    public enum FundAdjustmentAction {
        ADD_FUND,
        REMOVE_FUND,
        ADD_DEBT,
        REMOVE_DEBT
    }

    public record ConfirmExternalPaymentRequest(
            @Size(max = 500) String note
    ) {
    }

    public record UpdateMenuItemRequest(
            @Size(max = 255) String name,
            @Size(max = 2_000_000) String imageUrl,
            @PositiveOrZero Double calories,
            @PositiveOrZero Double protein,
            @PositiveOrZero Double carbs,
            @PositiveOrZero Double fat,
            @Positive Long unitPrice
    ) {
    }

    public record DishReviewRequest(
            @NotBlank String menuItemId,
            @NotNull @Min(1) @Max(5) Integer rating,
            @Size(max = 1000) String comment
    ) {
    }

    public record PaymentSettingsResponse(
            String qrImageUrl,
            String bankName,
            String accountName,
            String accountNumber,
            String instructions,
            LocalDateTime updatedAt
    ) {
    }

    public record UpdatePaymentSettingsRequest(
            @Size(max = 2_000_000) String qrImageUrl,
            @Size(max = 120) String bankName,
            @Size(max = 120) String accountName,
            @Size(max = 80) String accountNumber,
            @Size(max = 500) String instructions
    ) {
    }

    public record CreatePaymentRequest(
            @NotNull LunchPaymentRequestType type,
            @NotNull @Positive Long amount,
            @Size(max = 500) String note
    ) {
    }

    public record ReviewPaymentRequest(
            @Size(max = 500) String note
    ) {
    }

    public record PaymentRequestResponse(
            String id,
            PersonResponse user,
            String type,
            Long amount,
            String status,
            String note,
            PersonResponse reviewedBy,
            String reviewNote,
            LocalDateTime createdAt,
            LocalDateTime reviewedAt
    ) {
    }

    public record NotificationResponse(
            String id,
            String type,
            String title,
            String message,
            String referenceType,
            String referenceId,
            LocalDateTime createdAt,
            LocalDateTime readAt
    ) {
    }

    public record NotificationListResponse(
            long unreadCount,
            List<NotificationResponse> notifications
    ) {
    }

    public record MemberResponse(
            String id,
            String fullName,
            String email,
            Long walletBalance,
            Long outstandingDebt,
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
