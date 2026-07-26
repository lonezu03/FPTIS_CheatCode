package com.fittrack.lunch.mapper;

import com.fittrack.lunch.dto.LunchDtos.*;
import com.fittrack.lunch.entity.*;
import com.fittrack.lunch.service.LunchTextFormatter;
import com.fittrack.user.entity.User;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;
import java.util.Comparator;
import java.util.List;

@Component
@RequiredArgsConstructor
public class LunchMapper {

    private final LunchTextFormatter textFormatter;

    public MenuResponse toMenuResponse(
            LunchMenu menu,
            long totalOrders,
            long unpaidOrders,
            LocalDateTime now
    ) {
        List<MenuItemResponse> regularItems = menu.getItems().stream()
                .filter(item -> item.getType() == LunchMenuItemType.REGULAR)
                .sorted(Comparator.comparing(LunchMenuItem::getSortOrder))
                .map(this::toMenuItemResponse)
                .toList();
        List<MenuItemResponse> specialItems = menu.getItems().stream()
                .filter(item -> item.getType() == LunchMenuItemType.SPECIAL)
                .sorted(Comparator.comparing(LunchMenuItem::getSortOrder))
                .map(this::toMenuItemResponse)
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
                regularItems,
                specialItems,
                totalOrders,
                unpaidOrders
        );
    }

    public MenuItemResponse toMenuItemResponse(LunchMenuItem item) {
        return new MenuItemResponse(
                item.getId(),
                item.getName(),
                item.getType().name(),
                item.getSortOrder()
        );
    }

    public OrderResponse toOrderResponse(LunchOrder order) {
        List<MenuItemResponse> items = order.getItems().stream()
                .sorted(Comparator.comparing(LunchOrderItem::getSortOrder))
                .map(item -> new MenuItemResponse(
                        item.getMenuItem().getId(),
                        item.getItemNameSnapshot(),
                        item.getMenuItem().getType().name(),
                        item.getMenuItem().getSortOrder()
                ))
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
                order.getCreatedAt()
        );
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
