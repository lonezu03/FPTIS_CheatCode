package com.fittrack.lunch.service;

import com.fittrack.common.exception.ConflictException;
import com.fittrack.common.exception.ResourceNotFoundException;
import com.fittrack.lunch.dto.LunchDtos.*;
import com.fittrack.lunch.entity.*;
import com.fittrack.lunch.mapper.LunchMapper;
import com.fittrack.lunch.repository.*;
import com.fittrack.user.entity.User;
import com.fittrack.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.*;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import com.fittrack.common.dto.PageResponse;

@Service
@RequiredArgsConstructor
public class LunchService {

    private static final ZoneId BUSINESS_ZONE = ZoneId.of("Asia/Ho_Chi_Minh");

    private final LunchMenuRepository menuRepository;
    private final LunchOrderRepository orderRepository;
    private final LunchFundAccountRepository accountRepository;
    private final LunchFundTransactionRepository transactionRepository;
    private final UserRepository userRepository;
    private final LunchOrderRules orderRules;
    private final LunchTextFormatter textFormatter;
    private final LunchMapper mapper;
    private final LunchAccountService accountService;
    private final LunchNutritionService nutritionService;
    private final LunchDishReviewRepository reviewRepository;

    @Transactional(readOnly = true)
    public TodayResponse getToday(User user) {
        LocalDate today = now().toLocalDate();
        LocalDateTime currentTime = now();
        List<LunchMenu> menus = menuRepository.findByMenuDateOrderByCreatedAtAsc(today);
        long walletBalance = accountService.netBalance(user);
        long outstandingDebt = accountService.outstandingDebt(user);

        if (menus.isEmpty()) {
            return new TodayResponse(
                    null, walletBalance, outstandingDebt, null, List.of(), List.of(), false,
                    "Chưa có thực đơn hôm nay", List.of(), false
            );
        }

        List<MenuResponse> menuResponses = menus.stream()
                .map(menu -> mapper.toMenuResponse(menu, activeOrderCount(menu), unpaidOrderCount(menu), currentTime))
                .toList();
        List<OrderResponse> myMealOrders = menus.stream()
                .flatMap(menu -> orderRepository.findByMenuAndBeneficiaryAndStatusOrderByCreatedAtAsc(
                        menu, user, LunchOrderStatus.ACTIVE).stream())
                .map(mapper::toOrderResponse)
                .toList();
        List<OrderResponse> placedForOthers = menus.stream()
                .flatMap(menu -> orderRepository.findByMenuAndOrderedByAndStatusOrderByCreatedAtAsc(
                        menu, user, LunchOrderStatus.ACTIVE).stream())
                .filter(order -> !sameUser(order.getBeneficiary(), user))
                .map(mapper::toOrderResponse)
                .toList();

        boolean canOrder = menuResponses.stream().anyMatch(MenuResponse::acceptingOrders);
        String blockReason = canOrder ? null
                : menuResponses.stream().allMatch(response -> response.status().equals(LunchMenuStatus.CLOSED.name()))
                    ? "Các thực đơn hôm nay đã đóng"
                    : "Đã qua giờ chốt món";
        return new TodayResponse(
                menus.size() == 1 ? menuResponses.getFirst() : null,
                walletBalance,
                outstandingDebt,
                myMealOrders.isEmpty() ? null : myMealOrders.getFirst(),
                myMealOrders,
                placedForOthers,
                canOrder,
                blockReason,
                menuResponses,
                menus.size() > 1
        );
    }

    @Transactional(readOnly = true)
    public List<PersonResponse> getPeople(User currentUser) {
        return userRepository.findAll().stream()
                .filter(user -> !sameUser(user, currentUser))
                .filter(this::hasLunchAccess)
                .sorted(Comparator
                        .comparing(
                                User::getFullName,
                                Comparator.nullsLast(String.CASE_INSENSITIVE_ORDER)
                        )
                        .thenComparing(User::getEmail, String.CASE_INSENSITIVE_ORDER))
                .map(mapper::toPersonResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<WalletTransactionResponse> getWalletTransactions(User user) {
        return accountRepository.findByUser(user)
                .map(account -> transactionRepository
                        .findByAccountOrderByCreatedAtDesc(account)
                        .stream()
                        .map(mapper::toTransactionResponse)
                        .toList())
                .orElseGet(List::of);
    }

    @Transactional(readOnly = true)
    public List<OrderResponse> getOrderHistory(User user) {
        return orderRepository.findHistoryForUser(user)
                .stream()
                .map(mapper::toOrderResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public PageResponse<WalletTransactionResponse> getWalletTransactionsPage(
            User user, int page, int size
    ) {
        PageRequest pageable = PageRequest.of(
                Math.max(page, 0), Math.min(Math.max(size, 1), 100)
        );
        Page<WalletTransactionResponse> result = accountRepository.findByUser(user)
                .map(account -> transactionRepository
                        .findByAccountOrderByCreatedAtDesc(account, pageable)
                        .map(mapper::toTransactionResponse))
                .orElseGet(() -> Page.empty(pageable));
        return PageResponse.from(result);
    }

    @Transactional(readOnly = true)
    public PageResponse<OrderResponse> getOrderHistoryPage(
            User user, int page, int size
    ) {
        var result = orderRepository.findHistoryForUser(
                user,
                PageRequest.of(Math.max(page, 0), Math.min(Math.max(size, 1), 100))
        ).map(mapper::toOrderResponse);
        return PageResponse.from(result);
    }

    @Transactional
    public OrderResponse createOrder(User actor, CreateOrderRequest request) {
        LunchMenu menu = getMenuForUpdate(request.menuId());
        ensureAcceptingOrders(menu);

        return createOrder(
                actor,
                menu,
                request.beneficiaryUserId(),
                request.selectionType(),
                request.itemIds(),
                request.extraItemIds(),
                request.note(),
                null,
                null
        );
    }

    /**
     * Creates every selected portion in a single transaction. Any invalid
     * portion rolls back the entire cart.
     */
    @Transactional
    public OrderBatchResponse createOrderBatch(
            User actor,
            CreateOrderBatchRequest request
    ) {
        LunchMenu menu = getMenuForUpdate(request.menuId());

        OrderBatchResponse priorBatch = findExistingBatch(
                actor,
                request.clientRequestId(),
                menu.getId()
        );
        if (priorBatch != null) {
            return priorBatch;
        }
        ensureAcceptingOrders(menu);

        List<PreparedPortion> portions = new ArrayList<>();
        for (OrderPortionRequest portion : request.portions()) {
            if (portion == null) {
                throw new IllegalArgumentException("Danh sách phần ăn có dữ liệu không hợp lệ");
            }
            User beneficiary = resolveBeneficiary(actor, portion.beneficiaryUserId());
            List<LunchMenuItem> selectedItems = resolveSelectedItems(menu, portion.itemIds());
            List<LunchMenuItem> extraItems = resolveExtraItems(menu, portion.extraItemIds());
            orderRules.validateSelection(portion.selectionType(), selectedItems);
            portions.add(new PreparedPortion(
                    portions.size(),
                    beneficiary,
                    portion.selectionType(),
                    selectedItems,
                    extraItems,
                    portion.note()
            ));
        }

        List<OrderResponse> created = new ArrayList<>();
        long totalPrice = 0L;
        for (PreparedPortion portion : portions) {
            OrderResponse order = createOrder(
                    actor,
                    menu,
                    portion.beneficiary().getId(),
                    portion.selectionType(),
                    portion.itemIds(),
                    portion.extraItemIds(),
                    portion.note(),
                    request.clientRequestId(),
                    portion.position()
            );
            created.add(order);
            totalPrice = Math.addExact(totalPrice, order.price());
        }
        return new OrderBatchResponse(List.copyOf(created), totalPrice);
    }

    private OrderResponse createOrder(
            User actor,
            LunchMenu menu,
            String beneficiaryUserId,
            LunchSelectionType selectionType,
            List<String> itemIds,
            List<String> extraItemIds,
            String note,
            String batchRequestId,
            Integer batchPosition
    ) {
        User beneficiary = resolveBeneficiary(actor, beneficiaryUserId);
        List<LunchMenuItem> selectedItems = resolveSelectedItems(menu, itemIds);
        List<LunchMenuItem> extraItems = resolveExtraItems(menu, extraItemIds);
        orderRules.validateSelection(selectionType, selectedItems);

        LunchOrder order = LunchOrder.builder()
                .menu(menu)
                .beneficiary(beneficiary)
                .batchRequestId(batchRequestId)
                .batchPosition(batchPosition)
                .build();
        resetOrder(
                order,
                actor,
                beneficiary,
                menu,
                selectionType,
                selectedItems,
                extraItems,
                note
        );
        LunchOrder saved = orderRepository.save(order);
        accountService.debitOrder(
                beneficiary,
                saved.getPrice(),
                saved,
                actor,
                "Ghi nợ phần ăn " + saved.getMenu().getMenuDate()
        );
        nutritionService.syncOrder(saved);

        return mapper.toOrderResponse(saved);
    }

    /**
     * The menu row is already locked by the caller. Therefore two retrying
     * requests for the same checkout cannot both observe an empty batch.
     */
    private OrderBatchResponse findExistingBatch(
            User actor,
            String clientRequestId,
            String expectedMenuId
    ) {
        List<LunchOrder> existing = orderRepository
                .findByOrderedByAndBatchRequestIdOrderByCreatedAtAsc(actor, clientRequestId);
        if (existing.isEmpty()) {
            return null;
        }
        if (existing.stream().anyMatch(order -> !Objects.equals(
                order.getMenu().getId(),
                expectedMenuId
        ))) {
            throw new ConflictException("Mã gửi đơn này đã được dùng cho thực đơn khác");
        }

        List<OrderResponse> orders = existing.stream().map(mapper::toOrderResponse).toList();
        long totalPrice = orders.stream().mapToLong(OrderResponse::price).sum();
        return new OrderBatchResponse(orders, totalPrice);
    }

    private record PreparedPortion(
            int position,
            User beneficiary,
            LunchSelectionType selectionType,
            List<LunchMenuItem> selectedItems,
            List<LunchMenuItem> extraItems,
            String note
    ) {
        List<String> itemIds() {
            return selectedItems.stream().map(LunchMenuItem::getId).toList();
        }

        List<String> extraItemIds() {
            return extraItems.stream().map(LunchMenuItem::getId).toList();
        }
    }

    @Transactional
    public OrderResponse updateOrder(
            User actor,
            String orderId,
            UpdateOrderRequest request
    ) {
        LunchOrder order = getOrderForUpdate(orderId);
        ensureCanManage(actor, order);
        ensureOrderActive(order);
        ensureAcceptingOrders(order.getMenu());

        List<LunchMenuItem> selectedItems = resolveSelectedItems(
                order.getMenu(),
                request.itemIds()
        );
        List<LunchMenuItem> extraItems = resolveExtraItems(order.getMenu(), request.extraItemIds());
        orderRules.validateSelection(request.selectionType(), selectedItems);

        long previousPrice = order.getPrice();
        long updatedPrice = Math.addExact(order.getMenu().getPrice(), extraItems.stream()
                .mapToLong(item -> item.getUnitPrice() == null ? 0L : item.getUnitPrice()).sum());
        if (order.getPaymentStatus() == LunchPaymentStatus.PAID_FUND && previousPrice != updatedPrice) {
            if (updatedPrice > previousPrice) {
                User payer = order.getPayer();
                if (payer == null) {
                    throw new IllegalStateException("Đơn đã trừ quỹ nhưng không có người thanh toán");
                }
                accountService.debitOrder(
                        payer, updatedPrice - previousPrice, order, actor,
                        "Điều chỉnh tăng giá đơn do món thêm"
                );
            } else {
                accountService.credit(
                        order.getPayer(), previousPrice - updatedPrice,
                        LunchFundTransactionType.ORDER_REFUND, order, actor,
                        "Hoàn chênh lệch khi bỏ món thêm"
                );
            }
        }

        order.setSelectionType(request.selectionType());
        order.setPrice(updatedPrice);
        order.setNote(textFormatter.sanitizeNote(request.note()));
        reviewRepository.deleteByOrder(order);
        replaceOrderItems(order, selectedItems, extraItems);

        LunchOrder saved = orderRepository.save(order);
        nutritionService.syncOrder(saved);
        return mapper.toOrderResponse(saved);
    }

    @Transactional
    public void cancelOrder(User actor, String orderId) {
        LunchOrder order = getOrderForUpdate(orderId);
        ensureCanManage(actor, order);
        ensureOrderActive(order);
        ensureAcceptingOrders(order.getMenu());

        if (order.getPaymentStatus() == LunchPaymentStatus.PAID_FUND) {
            User payer = order.getPayer();
            if (payer == null) {
                throw new IllegalStateException("Đơn đã trừ quỹ nhưng không có người thanh toán");
            }
            accountService.credit(
                    payer,
                    order.getPrice(),
                    LunchFundTransactionType.ORDER_REFUND,
                    order,
                    actor,
                    "Hoàn ghi nợ phần ăn " + order.getMenu().getMenuDate()
            );
        }

        reviewRepository.deleteByOrder(order);
        order.setStatus(LunchOrderStatus.CANCELLED);
        order.setCancelledAt(now());
        orderRepository.save(order);
        nutritionService.removeOrder(order.getId());
    }

    private void resetOrder(
            LunchOrder order,
            User actor,
            User beneficiary,
            LunchMenu menu,
            LunchSelectionType selectionType,
            List<LunchMenuItem> selectedItems,
            List<LunchMenuItem> extraItems,
            String note
    ) {
        order.setMenu(menu);
        order.setBeneficiary(beneficiary);
        order.setOrderedBy(actor);
        // The beneficiary owns both the meal and its fund/debt. The actor is
        // retained separately in orderedBy for authorization and audit history.
        order.setPayer(beneficiary);
        order.setSelectionType(selectionType);
        order.setPrice(Math.addExact(menu.getPrice(), extraItems.stream()
                .mapToLong(item -> item.getUnitPrice() == null ? 0L : item.getUnitPrice()).sum()));
        order.setPaymentStatus(LunchPaymentStatus.PAID_FUND);
        order.setStatus(LunchOrderStatus.ACTIVE);
        order.setNote(textFormatter.sanitizeNote(note));
        order.setExternalConfirmedBy(null);
        order.setExternalConfirmedAt(null);
        order.setExternalPaymentNote(null);
        order.setCancelledAt(null);
        order.setCreatedAt(now());
        if (order.getId() != null) {
            reviewRepository.deleteByOrder(order);
        }
        replaceOrderItems(order, selectedItems, extraItems);
    }

    private void replaceOrderItems(
            LunchOrder order,
            List<LunchMenuItem> selectedItems,
            List<LunchMenuItem> extraItems
    ) {
        order.getItems().clear();
        List<LunchMenuItem> allItems = new ArrayList<>(selectedItems);
        allItems.addAll(extraItems);
        for (int index = 0; index < allItems.size(); index++) {
            LunchMenuItem menuItem = allItems.get(index);
            order.getItems().add(LunchOrderItem.builder()
                    .order(order)
                    .menuItem(menuItem)
                    .itemNameSnapshot(menuItem.getName())
                    .sortOrder(index)
                    .build());
        }
    }

    private List<LunchMenuItem> resolveSelectedItems(
            LunchMenu menu,
            List<String> itemIds
    ) {
        if (itemIds == null) {
            throw new IllegalArgumentException("Vui lòng chọn món");
        }
        Map<String, LunchMenuItem> availableItems = new HashMap<>();
        for (LunchMenuItem item : menu.getItems()) {
            availableItems.put(item.getId(), item);
        }

        List<LunchMenuItem> selected = new ArrayList<>();
        for (String itemId : itemIds) {
            LunchMenuItem item = availableItems.get(itemId);
            if (item == null) {
                throw new IllegalArgumentException("Món không thuộc thực đơn này");
            }
            selected.add(item);
        }
        return selected;
    }

    private List<LunchMenuItem> resolveExtraItems(LunchMenu menu, List<String> itemIds) {
        if (itemIds == null || itemIds.isEmpty()) {
            return List.of();
        }
        Map<String, LunchMenuItem> availableItems = new HashMap<>();
        for (LunchMenuItem item : menu.getItems()) {
            if (item.getType() == LunchMenuItemType.EXTRA) {
                availableItems.put(item.getId(), item);
            }
        }
        List<LunchMenuItem> selected = new ArrayList<>();
        for (String itemId : itemIds) {
            LunchMenuItem item = availableItems.get(itemId);
            if (item == null || item.getUnitPrice() == null || item.getUnitPrice() <= 0) {
                throw new IllegalArgumentException("Món thêm không thuộc thực đơn hoặc chưa có giá");
            }
            selected.add(item);
        }
        return selected;
    }

    private User resolveBeneficiary(User actor, String beneficiaryUserId) {
        if (beneficiaryUserId == null
                || beneficiaryUserId.isBlank()
                || beneficiaryUserId.equals(actor.getId())) {
            return actor;
        }
        User beneficiary = userRepository.findById(beneficiaryUserId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy người nhận"));
        if (!Boolean.TRUE.equals(beneficiary.getActive())) {
            throw new ConflictException("Tài khoản người nhận đang bị khóa");
        }
        if (!hasLunchAccess(beneficiary)) {
            throw new ConflictException("Người nhận chưa được cấp quyền sử dụng Đặt cơm");
        }
        return beneficiary;
    }

    private boolean hasLunchAccess(User user) {
        return Boolean.TRUE.equals(user.getActive())
                && ("ADMIN".equalsIgnoreCase(user.getRole())
                || Boolean.TRUE.equals(user.getLunchEnabled()));
    }

    private LunchMenu getMenuForUpdate(String menuId) {
        return menuRepository.findByIdForUpdate(menuId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy thực đơn"));
    }

    private LunchOrder getOrderForUpdate(String orderId) {
        return orderRepository.findByIdForUpdate(orderId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy đơn đặt món"));
    }

    private void ensureAcceptingOrders(LunchMenu menu) {
        if (menu.getStatus() != LunchMenuStatus.OPEN || menu.getSummarizedAt() != null) {
            throw new ConflictException("Thực đơn đã đóng");
        }
        if (!now().isBefore(menu.getCutoffAt())) {
            throw new ConflictException("Đã qua giờ chốt món");
        }
    }

    private void ensureCanManage(User actor, LunchOrder order) {
        if (!sameUser(actor, order.getBeneficiary())
                && !sameUser(actor, order.getOrderedBy())) {
            throw new org.springframework.security.access.AccessDeniedException(
                    "Bạn không có quyền thay đổi đơn này"
            );
        }
    }

    private void ensureOrderActive(LunchOrder order) {
        if (order.getStatus() != LunchOrderStatus.ACTIVE) {
            throw new ConflictException("Đơn đặt món đã bị hủy");
        }
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

    private boolean sameUser(User first, User second) {
        return first != null
                && second != null
                && Objects.equals(first.getId(), second.getId());
    }

    private LocalDateTime now() {
        return LocalDateTime.now(BUSINESS_ZONE);
    }
}
