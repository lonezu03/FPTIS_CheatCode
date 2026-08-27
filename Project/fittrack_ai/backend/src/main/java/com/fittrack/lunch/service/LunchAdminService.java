package com.fittrack.lunch.service;

import com.fittrack.common.exception.ConflictException;
import com.fittrack.common.exception.ResourceNotFoundException;
import com.fittrack.lunch.dto.LunchDtos.*;
import com.fittrack.lunch.entity.*;
import com.fittrack.lunch.mapper.LunchMapper;
import com.fittrack.lunch.repository.*;
import com.fittrack.user.entity.User;
import com.fittrack.user.repository.UserRepository;
import com.fittrack.common.media.ImageReferences;
import com.fittrack.common.media.MediaStorageService;
import com.fittrack.audit.service.AuditService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.*;

@Service
@RequiredArgsConstructor
public class LunchAdminService {

    private static final ZoneId BUSINESS_ZONE = ZoneId.of("Asia/Ho_Chi_Minh");
    private static final long DEFAULT_PRICE = 35_000L;

    private final LunchMenuRepository menuRepository;
    private final LunchOrderRepository orderRepository;
    private final UserRepository userRepository;
    private final LunchMenuParser menuParser;
    private final LunchTextFormatter textFormatter;
    private final LunchMapper mapper;
    private final LunchMenuItemRepository menuItemRepository;
    private final LunchAccountService accountService;
    private final LunchNutritionService nutritionService;
    private final AuditService auditService;
    private final MediaStorageService mediaStorageService;
    private final LunchNotificationService notificationService;

    @Transactional
    public MenuResponse importMenu(User admin, ImportMenuRequest request) {
        if (menuRepository.existsByMenuDate(request.menuDate())) {
            throw new ConflictException("Ngày này đã có thực đơn");
        }
        if (!request.cutoffAt().toLocalDate().equals(request.menuDate())) {
            throw new IllegalArgumentException("Giờ chốt món phải cùng ngày với thực đơn");
        }
        if (!request.cutoffAt().isAfter(now())) {
            throw new IllegalArgumentException("Giờ chốt món phải ở tương lai");
        }

        LunchMenuParser.ParsedMenu parsed = menuParser.parse(request.rawMenuText());
        long price = request.price() == null ? DEFAULT_PRICE : request.price();
        String orderLabel = request.orderLabel() == null || request.orderLabel().isBlank()
                ? defaultOrderLabel(admin)
                : request.orderLabel().trim();
        String vendorName = request.vendorName() == null || request.vendorName().isBlank()
                ? "Quán cơm"
                : request.vendorName().trim();

        LunchMenu menu = LunchMenu.builder()
                .menuDate(request.menuDate())
                .orderLabel(orderLabel)
                .vendorName(vendorName)
                .cutoffAt(request.cutoffAt())
                .price(price)
                .status(LunchMenuStatus.OPEN)
                .rawMenuText(request.rawMenuText().trim())
                .createdBy(admin)
                .build();

        for (LunchMenuParser.ParsedItem parsedItem : parsed.allItems()) {
            menu.getItems().add(LunchMenuItem.builder()
                    .menu(menu)
                    .name(parsedItem.name())
                    .type(parsedItem.type())
                    .sortOrder(parsedItem.sortOrder())
                    .build());
        }

        LunchMenu saved = menuRepository.save(menu);
        auditService.record(admin, "LUNCH_MENU_IMPORTED", "LUNCH_MENU", saved.getId(), Map.of(
                "menuDate", saved.getMenuDate().toString(),
                "itemCount", saved.getItems().size(),
                "price", saved.getPrice()
        ));
        return mapper.toMenuResponse(saved, 0, 0, now(), true);
    }

    /**
     * Replaces an imported menu before it has any order. The menu id is kept so
     * notifications and the admin's current selection do not become stale.
     */
    @Transactional
    public MenuResponse updateMenu(
            User admin,
            String menuId,
            UpdateMenuRequest request
    ) {
        LunchMenu menu = getMenuForUpdate(menuId);
        ensureMenuCanBeReplaced(menu);
        validateMenuTiming(request.menuDate(), request.cutoffAt());

        menuRepository.findByMenuDate(request.menuDate())
                .filter(other -> !Objects.equals(other.getId(), menu.getId()))
                .ifPresent(other -> {
                    throw new ConflictException("Ngày này đã có thực đơn");
                });

        LunchMenuParser.ParsedMenu parsed = menuParser.parse(request.rawMenuText());
        menu.setMenuDate(request.menuDate());
        menu.setOrderLabel(defaultOrderLabel(admin, request.orderLabel()));
        menu.setVendorName(defaultVendorName(request.vendorName()));
        menu.setCutoffAt(request.cutoffAt());
        menu.setPrice(request.price() == null ? DEFAULT_PRICE : request.price());
        menu.setRawMenuText(request.rawMenuText().trim());
        menu.setSummaryOrderText(null);
        menu.setSummarizedAt(null);
        // A valid replacement is a fresh draft. Reopen a manually closed,
        // order-free menu so the just-updated menu can receive orders.
        menu.setStatus(LunchMenuStatus.OPEN);
        replaceMenuItems(menu, parsed);

        LunchMenu saved = menuRepository.save(menu);
        auditService.record(admin, "LUNCH_MENU_UPDATED", "LUNCH_MENU", saved.getId(), Map.of(
                "menuDate", saved.getMenuDate().toString(),
                "itemCount", saved.getItems().size(),
                "price", saved.getPrice()
        ));
        return mapper.toMenuResponse(saved, 0, 0, now(), true);
    }

    /**
     * Deletes a draft menu only. Historical menus must remain intact because
     * orders, payment transactions and nutrition logs refer to them.
     */
    @Transactional
    public void deleteMenu(User admin, String menuId) {
        LunchMenu menu = getMenuForUpdate(menuId);
        ensureMenuCanBeReplaced(menu);
        auditService.record(admin, "LUNCH_MENU_DELETED", "LUNCH_MENU", menu.getId(), Map.of(
                "menuDate", menu.getMenuDate().toString(),
                "itemCount", menu.getItems().size()
        ));
        menuRepository.delete(menu);
    }

    public MenuNotificationResponse notifyMenu(User admin, String menuId) {
        LunchMenu menu = menuRepository.findById(menuId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy thực đơn"));
        LunchNotificationService.DeliverySummary result =
                notificationService.broadcastMenuAvailable(menu);
        auditService.record(admin, "LUNCH_MENU_NOTIFIED", "LUNCH_MENU", menu.getId(), Map.of(
                "recipientCount", result.recipientCount(),
                "emailSentCount", result.emailSentCount(),
                "emailFailedCount", result.emailFailedCount()
        ));
        return new MenuNotificationResponse(
                result.emailFailedCount() == 0
                        ? "Đã thông báo menu qua ứng dụng và email"
                        : "Đã tạo thông báo; một số email gửi thất bại",
                result.recipientCount(),
                result.emailSentCount(),
                result.emailFailedCount()
        );
    }

    @Transactional(readOnly = true)
    public List<MenuResponse> getMenus(LocalDate from, LocalDate to) {
        if (from != null && to != null && from.isAfter(to)) {
            throw new IllegalArgumentException("'from' không được sau 'to'");
        }

        List<LunchMenu> menus;
        if (from != null && to != null) {
            menus = menuRepository.findByMenuDateBetweenOrderByMenuDateDesc(from, to);
        } else if (from != null) {
            menus = menuRepository.findByMenuDateGreaterThanEqualOrderByMenuDateDesc(from);
        } else if (to != null) {
            menus = menuRepository.findByMenuDateLessThanEqualOrderByMenuDateDesc(to);
        } else {
            menus = menuRepository.findAllByOrderByMenuDateDesc();
        }

        LocalDateTime currentTime = now();
        return menus.stream()
                .map(menu -> mapper.toMenuResponse(
                        menu,
                        activeOrderCount(menu),
                        unpaidOrderCount(menu),
                        currentTime,
                        canReplaceMenu(menu)
                ))
                .toList();
    }

    @Transactional(readOnly = true)
    public List<OrderResponse> getMenuOrders(String menuId) {
        LunchMenu menu = menuRepository.findById(menuId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy thực đơn"));
        return orderRepository
                .findByMenuAndStatusOrderByCreatedAtAsc(menu, LunchOrderStatus.ACTIVE)
                .stream()
                .map(mapper::toOrderResponse)
                .toList();
    }

    @Transactional
    public SummaryResponse summarize(User admin, String menuId) {
        LunchMenu menu = getMenuForUpdate(menuId);
        List<LunchOrder> orders = orderRepository.findByMenuAndStatusForUpdate(
                menu,
                LunchOrderStatus.ACTIVE
        );

        if (menu.getSummarizedAt() == null) {
            menu.setStatus(LunchMenuStatus.CLOSED);
            menu.setSummarizedAt(now());
            menu.setSummaryOrderText(textFormatter.summaryText(menu, orders));
            menuRepository.save(menu);
            auditService.record(admin, "LUNCH_MENU_SUMMARIZED", "LUNCH_MENU", menu.getId(), Map.of(
                    "orderCount", orders.size()
            ));
            notificationService.broadcastMenuClosed(menu);
        }

        return buildSummary(menu, orders);
    }

    @Transactional
    public MenuResponse closeMenu(String menuId) {
        LunchMenu menu = getMenuForUpdate(menuId);
        boolean newlyClosed = menu.getStatus() != LunchMenuStatus.CLOSED;
        menu.setStatus(LunchMenuStatus.CLOSED);
        LunchMenu saved = menuRepository.save(menu);
        if (newlyClosed) {
            notificationService.broadcastMenuClosed(saved);
        }
        return mapper.toMenuResponse(
                saved,
                activeOrderCount(saved),
                unpaidOrderCount(saved),
                now(),
                canReplaceMenu(saved)
        );
    }

    @Transactional
    public MenuResponse reopenMenu(String menuId) {
        LunchMenu menu = getMenuForUpdate(menuId);
        if (menu.getSummarizedAt() != null) {
            throw new ConflictException("Thực đơn đã tổng hợp nên không thể mở lại");
        }
        if (!now().isBefore(menu.getCutoffAt())) {
            throw new ConflictException("Đã qua giờ chốt món nên không thể mở lại");
        }
        menu.setStatus(LunchMenuStatus.OPEN);
        LunchMenu saved = menuRepository.save(menu);
        return mapper.toMenuResponse(
                saved,
                activeOrderCount(saved),
                unpaidOrderCount(saved),
                now(),
                canReplaceMenu(saved)
        );
    }

    @Transactional(readOnly = true)
    public List<MemberResponse> getMembers() {
        return userRepository.findAll().stream()
                .sorted(Comparator
                        .comparing(
                                User::getFullName,
                                Comparator.nullsLast(String.CASE_INSENSITIVE_ORDER)
                        )
                        .thenComparing(User::getEmail, String.CASE_INSENSITIVE_ORDER))
                .map(user -> {
                    PersonResponse person = mapper.toPersonResponse(user);
                    return new MemberResponse(
                            person.id(),
                            person.fullName(),
                            person.email(),
                            accountService.netBalance(user),
                            accountService.outstandingDebt(user),
                            orderRepository.countByBeneficiaryAndStatusAndPaymentStatus(
                                    user,
                                    LunchOrderStatus.ACTIVE,
                                    LunchPaymentStatus.UNPAID
                            )
                    );
                })
                .toList();
    }

    @Transactional
    public WalletTransactionResponse adjustFund(
            User admin,
            FundAdjustmentRequest request
    ) {
        User member = userRepository.findById(request.userId())
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy thành viên"));
        String note = textFormatter.sanitizeNote(request.note());
        LunchFundTransaction transaction = accountService.adjust(
                member,
                request.amount(),
                request.action(),
                admin,
                note
        );
        auditService.record(admin, "LUNCH_FUND_ADJUSTMENT", "USER", member.getId(), Map.of(
                "action", request.action().name(),
                "amount", request.amount(),
                "transactionId", transaction.getId()
        ));
        return mapper.toTransactionResponse(transaction);
    }

    @Transactional
    public WalletTransactionResponse topUp(
            User admin,
            TopUpRequest request
    ) {
        User member = userRepository.findById(request.userId())
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy thành viên"));
        LunchFundTransaction transaction = accountService.credit(
                member,
                request.amount(),
                LunchFundTransactionType.TOP_UP,
                null,
                admin,
                textFormatter.sanitizeNote(request.note())
        );
        auditService.record(admin, "LUNCH_FUND_TOP_UP", "USER", member.getId(), Map.of(
                "amount", request.amount(),
                "transactionId", transaction.getId()
        ));
        return mapper.toTransactionResponse(transaction);
    }

    @Transactional
    public MenuItemResponse updateMenuItem(
            String itemId,
            UpdateMenuItemRequest request
    ) {
        LunchMenuItem item = menuItemRepository.findById(itemId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy món ăn"));
        if (request.name() != null && !request.name().isBlank()) {
            item.setName(request.name().trim());
        }
        item.setImageUrl(mediaStorageService.store(
                item.getImageUrl(),
                request.imageUrl(),
                ImageReferences.lunchItemPath(item.getId()),
                "lunch-items",
                item.getId()
        ));
        item.setCalories(request.calories());
        item.setProtein(request.protein());
        item.setCarbs(request.carbs());
        item.setFat(request.fat());
        nutritionService.ensureFood(item);
        LunchMenuItem saved = menuItemRepository.save(item);
        orderRepository.findDistinctByItems_MenuItemAndStatus(saved, LunchOrderStatus.ACTIVE)
                .forEach(nutritionService::syncOrder);
        return mapper.toMenuItemResponse(saved);
    }

    @Transactional
    public OrderResponse confirmExternalPayment(
            User admin,
            String orderId,
            ConfirmExternalPaymentRequest request
    ) {
        LunchOrder order = orderRepository.findByIdForUpdate(orderId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy đơn đặt món"));
        if (order.getStatus() != LunchOrderStatus.ACTIVE) {
            throw new ConflictException("Không thể xác nhận đơn đã hủy");
        }
        if (order.getPaymentStatus() == LunchPaymentStatus.PAID_FUND) {
            throw new ConflictException("Đơn này đã được thanh toán bằng quỹ");
        }
        if (order.getPaymentStatus() == LunchPaymentStatus.PAID_EXTERNAL) {
            return mapper.toOrderResponse(order);
        }

        order.setPaymentStatus(LunchPaymentStatus.PAID_EXTERNAL);
        order.setExternalConfirmedBy(admin);
        order.setExternalConfirmedAt(now());
        order.setExternalPaymentNote(
                request == null ? null : textFormatter.sanitizeNote(request.note())
        );
        LunchOrder saved = orderRepository.save(order);
        auditService.record(admin, "LUNCH_EXTERNAL_PAYMENT_CONFIRMED", "LUNCH_ORDER", saved.getId(), Map.of(
                "beneficiaryId", saved.getBeneficiary().getId(),
                "amount", saved.getPrice()
        ));
        return mapper.toOrderResponse(saved);
    }

    private SummaryResponse buildSummary(
            LunchMenu menu,
            List<LunchOrder> orders
    ) {
        long paidFund = orders.stream()
                .filter(order -> order.getPaymentStatus() == LunchPaymentStatus.PAID_FUND)
                .count();
        long paidExternal = orders.stream()
                .filter(order -> order.getPaymentStatus() == LunchPaymentStatus.PAID_EXTERNAL)
                .count();
        long unpaid = orders.stream()
                .filter(order -> order.getPaymentStatus() == LunchPaymentStatus.UNPAID)
                .count();
        long totalAmount = orders.stream()
                .mapToLong(LunchOrder::getPrice)
                .sum();

        Map<String, Long> dishCounts = new LinkedHashMap<>();
        for (LunchOrder order : orders) {
            for (LunchOrderItem item : order.getItems()) {
                dishCounts.merge(item.getItemNameSnapshot(), 1L, Long::sum);
            }
        }
        List<DishCountResponse> dishCountResponses = dishCounts.entrySet().stream()
                .map(entry -> new DishCountResponse(entry.getKey(), entry.getValue()))
                .toList();

        String orderText = menu.getSummaryOrderText() == null
                ? textFormatter.summaryText(menu, orders)
                : menu.getSummaryOrderText();
        return new SummaryResponse(
                orders.size(),
                paidFund,
                paidExternal,
                unpaid,
                totalAmount,
                orderText,
                dishCountResponses
        );
    }

    private void ensureMenuCanBeReplaced(LunchMenu menu) {
        if (!canReplaceMenu(menu)) {
            throw new ConflictException(
                    "Menu đã có đơn hoặc đã tổng hợp nên không thể thay thế/xóa. "
                            + "Hãy giữ lịch sử đơn và chỉ chỉnh sửa từng món khi cần."
            );
        }
    }

    private boolean canReplaceMenu(LunchMenu menu) {
        return menu.getSummarizedAt() == null && !orderRepository.existsByMenu(menu);
    }

    private void validateMenuTiming(LocalDate menuDate, LocalDateTime cutoffAt) {
        if (!cutoffAt.toLocalDate().equals(menuDate)) {
            throw new IllegalArgumentException("Giờ chốt món phải cùng ngày với thực đơn");
        }
        if (!cutoffAt.isAfter(now())) {
            throw new IllegalArgumentException("Giờ chốt món phải ở tương lai");
        }
    }

    private void replaceMenuItems(
            LunchMenu menu,
            LunchMenuParser.ParsedMenu parsed
    ) {
        menu.getItems().clear();
        // The database protects (menu_id, sort_order). Flush orphan removals
        // before adding the replacement list, otherwise Hibernate may insert a
        // new item at sort order 0 before deleting the old one.
        menuRepository.flush();
        for (LunchMenuParser.ParsedItem parsedItem : parsed.allItems()) {
            menu.getItems().add(LunchMenuItem.builder()
                    .menu(menu)
                    .name(parsedItem.name())
                    .type(parsedItem.type())
                    .sortOrder(parsedItem.sortOrder())
                    .build());
        }
    }

    private LunchMenu getMenuForUpdate(String menuId) {
        return menuRepository.findByIdForUpdate(menuId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy thực đơn"));
    }

    private long activeOrderCount(LunchMenu menu) {
        return orderRepository.countByMenuAndStatus(menu, LunchOrderStatus.ACTIVE);
    }

    private long unpaidOrderCount(LunchMenu menu) {
        return orderRepository.countByMenuAndStatusAndPaymentStatus(
                menu,
                LunchOrderStatus.ACTIVE,
                LunchPaymentStatus.UNPAID
        );
    }

    private String defaultOrderLabel(User admin) {
        if (admin.getFullName() != null && !admin.getFullName().isBlank()) {
            return admin.getFullName().trim();
        }
        return "Đặt cơm";
    }

    private String defaultOrderLabel(User admin, String requestedLabel) {
        String label = blankToNull(requestedLabel);
        return label == null ? defaultOrderLabel(admin) : label;
    }

    private String defaultVendorName(String requestedVendorName) {
        String vendorName = blankToNull(requestedVendorName);
        return vendorName == null ? "Quán cơm" : vendorName;
    }

    private String blankToNull(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }

    private LocalDateTime now() {
        return LocalDateTime.now(BUSINESS_ZONE);
    }
}
