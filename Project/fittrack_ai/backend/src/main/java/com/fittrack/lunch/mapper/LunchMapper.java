package com.fittrack.lunch.mapper;

import com.fittrack.lunch.dto.LunchDtos.*;
import com.fittrack.lunch.entity.*;
import com.fittrack.lunch.service.LunchTextFormatter;
import com.fittrack.lunch.repository.LunchDishReviewRepository;
import com.fittrack.user.entity.User;
import com.fittrack.common.media.ImageReferences;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;
import java.util.Collection;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Component
@RequiredArgsConstructor
public class LunchMapper {

    private final LunchTextFormatter textFormatter;
    private final LunchDishReviewRepository reviewRepository;

    public MenuResponse toMenuResponse(
            LunchMenu menu,
            long totalOrders,
            long unpaidOrders,
            LocalDateTime now
    ) {
        return toMenuResponse(menu, totalOrders, unpaidOrders, now, false);
    }

    public MenuResponse toMenuResponse(
            LunchMenu menu,
            long totalOrders,
            long unpaidOrders,
            LocalDateTime now,
            boolean canReplace
    ) {
        Map<String, ReviewStats> reviewStats = reviewStatsFor(menu.getItems());
        List<MenuItemResponse> regularItems = menu.getItems().stream()
                .filter(item -> item.getType() == LunchMenuItemType.REGULAR)
                .sorted(Comparator.comparing(LunchMenuItem::getSortOrder))
                .map(item -> toMenuItemResponse(
                        item,
                        reviewStats.getOrDefault(item.getId(), ReviewStats.EMPTY)
                ))
                .toList();
        List<MenuItemResponse> specialItems = menu.getItems().stream()
                .filter(item -> item.getType() == LunchMenuItemType.SPECIAL)
                .sorted(Comparator.comparing(LunchMenuItem::getSortOrder))
                .map(item -> toMenuItemResponse(
                        item,
                        reviewStats.getOrDefault(item.getId(), ReviewStats.EMPTY)
                ))
                .toList();

        boolean acceptingOrders = menu.getStatus() == LunchMenuStatus.OPEN
                && menu.getSummarizedAt() == null
                && now.isBefore(menu.getCutoffAt());

        return new MenuResponse(
                menu.getId(),
                menu.getMenuDate(),
                menu.getOrderLabel(),
                menu.getVendorName(),
                menu.getCutoffAt(),
                menu.getPrice(),
                menu.getStatus().name(),
                menu.getSummarizedAt() != null,
                acceptingOrders,
                canReplace,
                regularItems,
                specialItems,
                totalOrders,
                unpaidOrders
        );
    }

    public MenuItemResponse toMenuItemResponse(LunchMenuItem item) {
        ReviewStats stats = stats(
                reviewRepository.findByMenuItemAndOrder_StatusOrderByCreatedAtDesc(
                        item,
                        LunchOrderStatus.ACTIVE
                )
        );
        return toMenuItemResponse(item, stats);
    }

    private MenuItemResponse toMenuItemResponse(
            LunchMenuItem item,
            ReviewStats stats
    ) {
        return new MenuItemResponse(
                item.getId(),
                item.getName(),
                item.getType().name(),
                item.getSortOrder(),
                ImageReferences.responseUrl(
                        item.getImageUrl(),
                        ImageReferences.lunchItemPath(item.getId())
                ),
                item.getCalories(),
                item.getProtein(),
                item.getCarbs(),
                item.getFat(),
                stats.average(),
                stats.count()
        );
    }

    public OrderResponse toOrderResponse(LunchOrder order) {
        List<LunchMenuItem> menuItems = order.getItems().stream()
                .map(LunchOrderItem::getMenuItem)
                .toList();
        Map<String, ReviewStats> reviewStats = reviewStatsFor(menuItems);
        List<MenuItemResponse> items = order.getItems().stream()
                .sorted(Comparator.comparing(LunchOrderItem::getSortOrder))
                .map(item -> new MenuItemResponse(
                        item.getMenuItem().getId(),
                        item.getItemNameSnapshot(),
                        item.getMenuItem().getType().name(),
                        item.getMenuItem().getSortOrder(),
                        ImageReferences.responseUrl(
                                item.getMenuItem().getImageUrl(),
                                ImageReferences.lunchItemPath(item.getMenuItem().getId())
                        ),
                        item.getMenuItem().getCalories(),
                        item.getMenuItem().getProtein(),
                        item.getMenuItem().getCarbs(),
                        item.getMenuItem().getFat(),
                        reviewStats.getOrDefault(
                                item.getMenuItem().getId(),
                                ReviewStats.EMPTY
                        ).average(),
                        reviewStats.getOrDefault(
                                item.getMenuItem().getId(),
                                ReviewStats.EMPTY
                        ).count()
                ))
                .toList();
        List<DishReviewResponse> reviews = reviewRepository.findByOrderOrderByCreatedAtAsc(order)
                .stream()
                .map(this::toReviewResponse)
                .toList();

        return new OrderResponse(
                order.getId(),
                order.getMenu().getId(),
                order.getMenu().getMenuDate(),
                toPersonResponse(order.getBeneficiary()),
                toPersonResponse(order.getPayer()),
                toPersonResponse(order.getOrderedBy()),
                order.getSelectionType().name(),
                items,
                order.getNote(),
                textFormatter.displayText(order),
                order.getPrice(),
                order.getPaymentStatus().name(),
                order.getStatus().name(),
                order.getCreatedAt(),
                reviews
        );
    }

    public DishReviewResponse toReviewResponse(LunchDishReview review) {
        return new DishReviewResponse(
                review.getId(),
                review.getOrder().getId(),
                review.getMenuItem().getId(),
                review.getMenuItem().getName(),
                toPersonResponse(review.getReviewer()),
                review.getRating(),
                review.getComment(),
                review.getCreatedAt(),
                review.getUpdatedAt()
        );
    }

    public PaymentRequestResponse toPaymentRequestResponse(LunchPaymentRequest request) {
        return new PaymentRequestResponse(
                request.getId(),
                toPersonResponse(request.getUser()),
                request.getType().name(),
                request.getAmount(),
                request.getStatus().name(),
                request.getNote(),
                toPersonResponse(request.getReviewedBy()),
                request.getReviewNote(),
                request.getCreatedAt(),
                request.getReviewedAt()
        );
    }

    public NotificationResponse toNotificationResponse(LunchNotification notification) {
        return new NotificationResponse(
                notification.getId(),
                notification.getType(),
                notification.getTitle(),
                notification.getMessage(),
                notification.getReferenceType(),
                notification.getReferenceId(),
                notification.getCreatedAt(),
                notification.getReadAt()
        );
    }

    private Map<String, ReviewStats> reviewStatsFor(
            Collection<LunchMenuItem> menuItems
    ) {
        List<String> ids = menuItems.stream()
                .map(LunchMenuItem::getId)
                .filter(java.util.Objects::nonNull)
                .distinct()
                .toList();
        if (ids.isEmpty()) {
            return Map.of();
        }

        Map<String, List<LunchDishReview>> grouped = reviewRepository
                .findForMenuItems(ids, LunchOrderStatus.ACTIVE)
                .stream()
                .collect(java.util.stream.Collectors.groupingBy(
                        review -> review.getMenuItem().getId()
                ));
        Map<String, ReviewStats> result = new HashMap<>();
        grouped.forEach((id, reviews) -> result.put(id, stats(reviews)));
        return result;
    }

    private ReviewStats stats(List<LunchDishReview> reviews) {
        double average = reviews.stream()
                .mapToInt(LunchDishReview::getRating)
                .average()
                .orElse(0.0);
        return new ReviewStats(
                Math.round(average * 10.0) / 10.0,
                reviews.size()
        );
    }

    private record ReviewStats(double average, long count) {
        private static final ReviewStats EMPTY = new ReviewStats(0.0, 0L);
    }

    public PersonResponse toPersonResponse(User user) {
        if (user == null) {
            return null;
        }
        String fullName = user.getFullName() == null || user.getFullName().isBlank()
                ? user.getEmail()
                : user.getFullName();
        return new PersonResponse(user.getId(), fullName, user.getEmail());
    }

    public WalletTransactionResponse toTransactionResponse(LunchFundTransaction transaction) {
        return new WalletTransactionResponse(
                transaction.getId(),
                transaction.getType().name(),
                transaction.getAmount(),
                transaction.getBalanceAfter(),
                transaction.getNote(),
                transaction.getCreatedAt(),
                transaction.getOrder() == null ? null : transaction.getOrder().getId(),
                toPersonResponse(transaction.getActor())
        );
    }
}
