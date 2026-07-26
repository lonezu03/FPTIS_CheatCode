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

@Service
@RequiredArgsConstructor
public class LunchAdminService {

    private static final ZoneId BUSINESS_ZONE = ZoneId.of("Asia/Ho_Chi_Minh");
    private static final long DEFAULT_PRICE = 35_000L;

    private final LunchMenuRepository menuRepository;
    private final LunchOrderRepository orderRepository;
    private final LunchFundAccountRepository accountRepository;
    private final LunchFundTransactionRepository transactionRepository;
    private final UserRepository userRepository;
    private final LunchMenuParser menuParser;
    private final LunchTextFormatter textFormatter;
    private final LunchMapper mapper;

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
        return mapper.toMenuResponse(saved, 0, 0, now());
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
                        currentTime
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
        }

        return buildSummary(menu, orders);
    }

    @Transactional
    public MenuResponse closeMenu(String menuId) {
        LunchMenu menu = getMenuForUpdate(menuId);
        menu.setStatus(LunchMenuStatus.CLOSED);
        LunchMenu saved = menuRepository.save(menu);
        return mapper.toMenuResponse(
                saved,
                activeOrderCount(saved),
                unpaidOrderCount(saved),
                now()
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
                now()
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
                            accountRepository.findByUser(user)
                                    .map(LunchFundAccount::getBalance)
                                    .orElse(0L),
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
    public WalletTransactionResponse topUp(
            User admin,
            TopUpRequest request
    ) {
        User member = userRepository.findById(request.userId())
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy thành viên"));
        LunchFundAccount account = accountRepository.findByUserForUpdate(member)
                .orElseGet(() -> accountRepository.saveAndFlush(
                        LunchFundAccount.builder()
                                .user(member)
                                .balance(0L)
                                .build()
                ));

        long newBalance;
        try {
            newBalance = Math.addExact(account.getBalance(), request.amount());
        } catch (ArithmeticException exception) {
            throw new IllegalArgumentException("Số tiền vượt quá giới hạn cho phép");
        }
        account.setBalance(newBalance);

        LunchFundTransaction transaction = transactionRepository.save(
                LunchFundTransaction.builder()
                        .account(account)
                        .type(LunchFundTransactionType.TOP_UP)
                        .amount(request.amount())
                        .balanceAfter(newBalance)
                        .actor(admin)
                        .note(textFormatter.sanitizeNote(request.note()))
                        .createdAt(now())
                        .build()
        );
        return mapper.toTransactionResponse(transaction);
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
        return mapper.toOrderResponse(orderRepository.save(order));
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

    private LocalDateTime now() {
        return LocalDateTime.now(BUSINESS_ZONE);
    }
}
