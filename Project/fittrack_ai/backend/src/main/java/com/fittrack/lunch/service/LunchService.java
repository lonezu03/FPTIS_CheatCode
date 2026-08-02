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
        LunchMenu menu = menuRepository.findByMenuDate(today).orElse(null);
        long walletBalance = accountService.netBalance(user);
        long outstandingDebt = accountService.outstandingDebt(user);

        if (menu == null) {
            return new TodayResponse(
                    null,
                    walletBalance,
                    outstandingDebt,
                    null,
                    List.of(),
                    false,
                    "Chưa có thực đơn hôm nay"
            );
        }

        LunchOrder myOrder = orderRepository
                .findByMenuAndBeneficiaryAndStatus(menu, user, LunchOrderStatus.ACTIVE)
                .orElse(null);
        List<OrderResponse> placedForOthers = orderRepository
                .findByMenuAndOrderedByAndStatusOrderByCreatedAtAsc(
                        menu,
                        user,
                        LunchOrderStatus.ACTIVE
                )
                .stream()
                .filter(order -> !sameUser(order.getBeneficiary(), user))
                .map(mapper::toOrderResponse)
                .toList();

        long totalOrders = activeOrderCount(menu);
        long unpaidOrders = unpaidOrderCount(menu);
        MenuResponse menuResponse = mapper.toMenuResponse(
                menu,
                totalOrders,
                unpaidOrders,
                now()
        );

        String blockReason = null;
        if (!menuResponse.acceptingOrders()) {
            blockReason = menu.getStatus() == LunchMenuStatus.CLOSED
                    ? "Thực đơn đã đóng"
                    : "Đã qua giờ chốt món";
        }

        return new TodayResponse(
                menuResponse,
                walletBalance,
                outstandingDebt,
                myOrder == null ? null : mapper.toOrderResponse(myOrder),
                placedForOthers,
                blockReason == null,
                blockReason
        );
    }

    @Transactional(readOnly = true)
    public List<PersonResponse> getPeople(User currentUser) {
        return userRepository.findAll().stream()
                .filter(user -> !sameUser(user, currentUser))
                .filter(user -> Boolean.TRUE.equals(user.getActive()))
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

        User beneficiary = resolveBeneficiary(actor, request.beneficiaryUserId());
        boolean selfOrder = sameUser(actor, beneficiary);
        List<LunchMenuItem> selectedItems = resolveSelectedItems(menu, request.itemIds());
        orderRules.validateSelection(request.selectionType(), selectedItems);

        Optional<LunchOrder> existing = orderRepository
                .findByMenuAndBeneficiaryForUpdate(menu, beneficiary);
        if (existing.isPresent() && existing.get().getStatus() == LunchOrderStatus.ACTIVE) {
            throw new ConflictException("Người này đã có một phần ăn trong ngày");
        }

        LunchOrder order = existing.orElseGet(() -> LunchOrder.builder()
                .menu(menu)
                .beneficiary(beneficiary)
                .build());
        resetOrder(
                order,
                actor,
                beneficiary,
                menu,
                request.selectionType(),
                selectedItems,
                request.note(),
                true
        );
        LunchOrder saved = orderRepository.save(order);
        accountService.debitOrder(
                actor,
                saved.getPrice(),
                saved,
                actor,
                "Ghi nợ phần ăn " + saved.getMenu().getMenuDate(),
                selfOrder
        );
        nutritionService.syncOrder(saved);

        return mapper.toOrderResponse(saved);
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
        orderRules.validateSelection(request.selectionType(), selectedItems);

        order.setSelectionType(request.selectionType());
        order.setNote(textFormatter.sanitizeNote(request.note()));
        reviewRepository.deleteByOrder(order);
        replaceOrderItems(order, selectedItems);

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
            String note,
            boolean paidFromFund
    ) {
        order.setMenu(menu);
        order.setBeneficiary(beneficiary);
        order.setOrderedBy(actor);
        order.setPayer(paidFromFund ? actor : null);
        order.setSelectionType(selectionType);
        order.setPrice(menu.getPrice());
        order.setPaymentStatus(
                paidFromFund ? LunchPaymentStatus.PAID_FUND : LunchPaymentStatus.UNPAID
        );
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
        replaceOrderItems(order, selectedItems);
    }

    private void replaceOrderItems(LunchOrder order, List<LunchMenuItem> selectedItems) {
        order.getItems().clear();
        for (int index = 0; index < selectedItems.size(); index++) {
            LunchMenuItem menuItem = selectedItems.get(index);
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

    private User resolveBeneficiary(User actor, String beneficiaryUserId) {
        if (beneficiaryUserId == null
                || beneficiaryUserId.isBlank()
                || beneficiaryUserId.equals(actor.getId())) {
            return actor;
        }
        return userRepository.findById(beneficiaryUserId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy người nhận"));
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
