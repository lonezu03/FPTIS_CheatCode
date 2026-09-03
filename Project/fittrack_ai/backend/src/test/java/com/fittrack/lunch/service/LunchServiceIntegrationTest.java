package com.fittrack.lunch.service;

import com.fittrack.FittrackBackendApplication;
import com.fittrack.common.exception.ConflictException;
import com.fittrack.lunch.dto.LunchDtos.CreateOrderRequest;
import com.fittrack.lunch.dto.LunchDtos.CreateOrderBatchRequest;
import com.fittrack.lunch.dto.LunchDtos.OrderPortionRequest;
import com.fittrack.lunch.dto.LunchDtos.OrderResponse;
import com.fittrack.lunch.dto.LunchDtos.SummaryResponse;
import com.fittrack.lunch.dto.LunchDtos.UpdateMenuRequest;
import com.fittrack.lunch.dto.LunchDtos.UpdateOrderRequest;
import com.fittrack.lunch.dto.LunchDtos.CreatePaymentRequest;
import com.fittrack.lunch.dto.LunchDtos.ReviewPaymentRequest;
import com.fittrack.lunch.dto.LunchDtos.UpdatePaymentSettingsRequest;
import com.fittrack.lunch.dto.LunchDtos.DishReviewRequest;
import com.fittrack.nutrition.repository.MealLogRepository;
import com.fittrack.lunch.entity.*;
import com.fittrack.lunch.repository.*;
import com.fittrack.user.entity.User;
import com.fittrack.user.repository.UserRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Collections;
import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest(classes = FittrackBackendApplication.class)
@ActiveProfiles("test")
@Transactional
class LunchServiceIntegrationTest {

    @Autowired
    private LunchService lunchService;

    @Autowired
    private LunchAdminService lunchAdminService;

    @Autowired
    private LunchPaymentService lunchPaymentService;

    @Autowired
    private LunchReviewService lunchReviewService;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private LunchMenuRepository menuRepository;

    @Autowired
    private LunchMenuItemRepository menuItemRepository;

    @Autowired
    private LunchOrderRepository orderRepository;

    @Autowired
    private LunchFundAccountRepository accountRepository;

    @Autowired
    private LunchFundTransactionRepository transactionRepository;

    @Autowired
    private LunchNotificationRepository notificationRepository;

    @Autowired
    private MealLogRepository mealLogRepository;

    @Test
    void selfOrderWithInsufficientFundCreatesDebtAndLedgerDebit() {
        User user = saveUser("self-unpaid");
        LunchMenu menu = saveMenu(user, LocalDate.of(2099, 1, 10));

        OrderResponse response = lunchService.createOrder(
                user,
                comboRequest(menu, null)
        );

        assertEquals("PAID_FUND", response.paymentStatus());
        assertEquals(user.getId(), response.payer().id());
        LunchFundAccount account = accountRepository.findByUser(user).orElseThrow();
        assertEquals(0L, account.getBalance());
        assertEquals(35_000L, account.getDebt());
        LunchFundTransaction debit = transactionRepository
                .findByAccountOrderByCreatedAtDesc(account)
                .getFirst();
        assertEquals(-35_000L, debit.getAmount());
        assertEquals(-35_000L, debit.getBalanceAfter());
    }

    @Test
    void todayForNewUserWithoutMenuOrFundAccountReturnsEmptyState() {
        User user = saveUser("today-empty");

        var today = assertDoesNotThrow(() -> lunchService.getToday(user));

        assertNull(today.menu());
        assertEquals(0L, today.walletBalance());
        assertEquals(0L, today.outstandingDebt());
        assertFalse(today.canOrder());
        assertEquals("Chưa có thực đơn hôm nay", today.blockReason());
    }

    @Test
    void payingForAnotherUserDebitsAuthenticatedPayerAndCancelRefundsThatPayer() {
        User payer = saveUser("payer");
        User beneficiary = saveUser("beneficiary");
        LunchMenu menu = saveMenu(payer, LocalDate.of(2099, 1, 11));
        LunchFundAccount account = accountRepository.save(
                LunchFundAccount.builder()
                        .user(payer)
                        .balance(70_000L)
                        .build()
        );

        OrderResponse created = lunchService.createOrder(
                payer,
                comboRequest(menu, beneficiary.getId())
        );

        assertEquals("PAID_FUND", created.paymentStatus());
        assertEquals(payer.getId(), created.payer().id());
        assertEquals(35_000L, account.getBalance());

        lunchService.cancelOrder(beneficiary, created.id());

        assertEquals(70_000L, account.getBalance());
        List<LunchFundTransaction> transactions =
                transactionRepository.findByAccountOrderByCreatedAtDesc(account);
        assertEquals(2, transactions.size());
        assertEquals(35_000L, transactions.getFirst().getAmount());
        assertEquals(-35_000L, transactions.get(1).getAmount());
        assertEquals(
                LunchOrderStatus.CANCELLED,
                orderRepository.findById(created.id()).orElseThrow().getStatus()
        );
    }

    @Test
    void priorUnpaidOrderNoLongerBlocksOrderingNextDay() {
        User user = saveUser("prior-debt");
        LunchMenu previousMenu = saveMenu(user, LocalDate.of(2099, 1, 12));
        LunchOrder previousOrder = LunchOrder.builder()
                .menu(previousMenu)
                .beneficiary(user)
                .orderedBy(user)
                .selectionType(LunchSelectionType.COMBO)
                .price(35_000L)
                .paymentStatus(LunchPaymentStatus.UNPAID)
                .status(LunchOrderStatus.ACTIVE)
                .createdAt(LocalDateTime.now())
                .build();
        orderRepository.save(previousOrder);
        LunchMenu nextMenu = saveMenu(user, LocalDate.of(2099, 1, 13));

        OrderResponse response = lunchService.createOrder(user, comboRequest(nextMenu, null));

        assertEquals("PAID_FUND", response.paymentStatus());
        assertEquals(35_000L, accountRepository.findByUser(user).orElseThrow().getDebt());
    }

    @Test
    void currentDebtDoesNotBlockAnotherSelfOrder() {
        User user = saveUser("repeat-debt");
        LunchMenu firstMenu = saveMenu(user, LocalDate.of(2099, 1, 13));
        LunchMenu secondMenu = saveMenu(user, LocalDate.of(2099, 1, 14));

        lunchService.createOrder(user, comboRequest(firstMenu, null));
        OrderResponse secondOrder = lunchService.createOrder(user, comboRequest(secondMenu, null));

        LunchFundAccount account = accountRepository.findByUser(user).orElseThrow();
        assertEquals("PAID_FUND", secondOrder.paymentStatus());
        assertEquals(0L, account.getBalance());
        assertEquals(70_000L, account.getDebt());
        assertEquals(2, transactionRepository.findByAccountOrderByCreatedAtDesc(account).size());
    }

    @Test
    void lunchPeopleAndSponsoredOrdersHonorCurrentModulePermission() {
        User payer = saveUser("permission-payer");
        User disabledBeneficiary = saveUser("permission-disabled");
        disabledBeneficiary.setLunchEnabled(false);
        userRepository.saveAndFlush(disabledBeneficiary);
        LunchMenu menu = saveMenu(payer, LocalDate.of(2099, 1, 14));

        assertTrue(lunchService.getPeople(payer).stream()
                .noneMatch(person -> person.id().equals(disabledBeneficiary.getId())));
        assertThrows(
                ConflictException.class,
                () -> lunchService.createOrder(payer, comboRequest(menu, disabledBeneficiary.getId()))
        );
    }

    @Test
    void sponsoredOrderPriceIncreaseRequiresPayerAndSufficientFund() {
        User payer = saveUser("sponsor-update-payer");
        User beneficiary = saveUser("sponsor-update-beneficiary");
        LunchMenu menu = saveMenu(payer, LocalDate.of(2099, 1, 14));
        LunchMenuItem extra = LunchMenuItem.builder()
                .menu(menu)
                .name("Trà đào")
                .type(LunchMenuItemType.EXTRA)
                .sortOrder(3)
                .unitPrice(10_000L)
                .build();
        menuItemRepository.saveAndFlush(extra);
        menu.getItems().add(extra);
        LunchFundAccount account = accountRepository.save(
                LunchFundAccount.builder().user(payer).balance(40_000L).build()
        );
        OrderResponse order = lunchService.createOrder(payer, comboRequest(menu, beneficiary.getId()));
        UpdateOrderRequest update = new UpdateOrderRequest(
                LunchSelectionType.COMBO,
                List.of(menu.getItems().get(0).getId(), menu.getItems().get(1).getId()),
                List.of(extra.getId()),
                null
        );

        assertThrows(
                org.springframework.security.access.AccessDeniedException.class,
                () -> lunchService.updateOrder(beneficiary, order.id(), update)
        );
        assertThrows(
                ConflictException.class,
                () -> lunchService.updateOrder(payer, order.id(), update)
        );
        assertEquals(5_000L, account.getBalance());
        assertEquals(0L, account.getDebt());
        assertEquals(35_000L, orderRepository.findById(order.id()).orElseThrow().getPrice());
    }

    @Test
    void approvedDebtPaymentClearsDebtAndCreditsLedgerExactlyOnce() {
        User admin = saveUser("external-admin");
        User user = saveUser("external-user");
        LunchMenu menu = saveMenu(admin, LocalDate.of(2099, 1, 15));
        lunchService.createOrder(user, comboRequest(menu, null));
        lunchPaymentService.updateSettings(new UpdatePaymentSettingsRequest(
                "https://example.com/qr.png",
                "Test Bank",
                "FITTRACK",
                "123456",
                null
        ));
        var paymentRequest = lunchPaymentService.create(
                user,
                new CreatePaymentRequest(LunchPaymentRequestType.DEBT_PAYMENT, 35_000L, "Đã chuyển")
        );

        lunchPaymentService.approve(
                admin,
                paymentRequest.id(),
                new ReviewPaymentRequest("Đã nhận")
        );
        assertThrows(
                ConflictException.class,
                () -> lunchPaymentService.approve(
                        admin,
                        paymentRequest.id(),
                        new ReviewPaymentRequest("Duyệt lại")
                )
        );

        LunchFundAccount account = accountRepository.findByUser(user).orElseThrow();
        assertEquals(0L, account.getDebt());
        assertEquals(0L, account.getBalance());
        List<LunchFundTransaction> transactions =
                transactionRepository.findByAccountOrderByCreatedAtDesc(account);
        assertEquals(2, transactions.size());
        assertEquals(LunchFundTransactionType.DEBT_PAYMENT, transactions.getFirst().getType());
        assertEquals(35_000L, transactions.getFirst().getAmount());
    }

    @Test
    void summarizeClosesMenuAndStoresExactSnapshotThatCannotBeReopened() {
        User admin = saveUser("summary-admin");
        LunchMenu menu = saveMenu(admin, LocalDate.of(2099, 1, 14));
        lunchService.createOrder(admin, comboRequest(menu, null));

        SummaryResponse summary = lunchAdminService.summarize(admin, menu.getId());

        assertEquals(1, summary.totalOrders());
        assertEquals(1, summary.paidFundOrders());
        assertEquals(0, summary.unpaidOrders());
        assertEquals(35_000L, summary.totalAmount());
        assertEquals(2, summary.dishCounts().size());
        assertEquals("Sườn ram", summary.dishCounts().getFirst().dishName());
        assertEquals(1, summary.dishCounts().getFirst().count());
        assertEquals(
                """
                        Vũ - 14-01: 1 phần
                        - Sườn ram + Thịt kho""",
                summary.orderText()
        );
        assertEquals(LunchMenuStatus.CLOSED, menu.getStatus());
        assertNotNull(menu.getSummarizedAt());
        assertEquals(
                1,
                notificationRepository.findTop50ByRecipientOrderByCreatedAtDesc(admin)
                        .stream()
                        .filter(notification -> "LUNCH_MENU_CLOSED".equals(notification.getType()))
                        .count()
        );
        lunchAdminService.summarize(admin, menu.getId());
        assertEquals(
                1,
                notificationRepository.findTop50ByRecipientOrderByCreatedAtDesc(admin)
                        .stream()
                        .filter(notification -> "LUNCH_MENU_CLOSED".equals(notification.getType()))
                        .count()
        );
        assertThrows(
                ConflictException.class,
                () -> lunchAdminService.reopenMenu(menu.getId())
        );
    }

    @Test
    void lunchOrderSyncsNutritionAndBeneficiaryCanReviewEachDish() {
        User user = saveUser("nutrition-review");
        LunchMenu menu = saveMenu(user, LocalDate.of(2099, 1, 16));
        menu.getItems().get(0).setCalories(320.0);
        menu.getItems().get(0).setProtein(24.0);
        menu.getItems().get(0).setImageUrl("https://example.com/suon-ram.jpg");
        menu.getItems().get(1).setCalories(180.0);
        menu.getItems().get(1).setProtein(12.0);
        menuRepository.saveAndFlush(menu);

        OrderResponse order = lunchService.createOrder(user, comboRequest(menu, null));
        var mealLog = mealLogRepository.findBySourceLunchOrderId(order.id()).orElseThrow();

        assertEquals(500.0, mealLog.getTotalCalories());
        assertEquals(36.0, mealLog.getTotalProtein());
        assertEquals(2, mealLog.getItems().size());
        assertEquals(
                "https://example.com/suon-ram.jpg",
                mealLog.getItems().getFirst().getFood().getImageUrl()
        );

        var review = lunchReviewService.review(
                user,
                order.id(),
                new DishReviewRequest(menu.getItems().getFirst().getId(), 5, "Rất ngon")
        );

        assertEquals(5, review.rating());
        assertEquals("Rất ngon", review.comment());
        assertEquals(menu.getItems().getFirst().getId(), review.menuItemId());
    }

    @Test
    void userCanCreateMultiplePortionsForSameMenuInOneAtomicBatch() {
        User user = saveUser("batch-user");
        LunchMenu menu = saveMenu(user, LocalDate.of(2099, 1, 17));

        var response = lunchService.createOrderBatch(
                user,
                new CreateOrderBatchRequest(
                        menu.getId(),
                        "batch-idempotency-123456",
                        List.of(
                                new OrderPortionRequest(
                                        null,
                                        LunchSelectionType.COMBO,
                                        List.of(menu.getItems().get(0).getId(), menu.getItems().get(1).getId()),
                                        "Cơm thêm"
                                ),
                                new OrderPortionRequest(
                                        null,
                                        LunchSelectionType.SINGLE,
                                        List.of(menu.getItems().get(2).getId()),
                                        null
                                )
                        )
                )
        );

        assertEquals(2, response.orders().size());
        assertEquals(70_000L, response.totalPrice());
        assertEquals(
                2,
                orderRepository.findByMenuAndBeneficiaryAndStatusOrderByCreatedAtAsc(
                        menu,
                        user,
                        LunchOrderStatus.ACTIVE
                ).size()
        );
        LunchFundAccount account = accountRepository.findByUser(user).orElseThrow();
        assertEquals(70_000L, account.getDebt());
        assertEquals(2, transactionRepository.findByAccountOrderByCreatedAtDesc(account).size());

        var retryResponse = lunchService.createOrderBatch(
                user,
                new CreateOrderBatchRequest(
                        menu.getId(),
                        "batch-idempotency-123456",
                        List.of(new OrderPortionRequest(
                                null,
                                LunchSelectionType.COMBO,
                                List.of(menu.getItems().get(0).getId(), menu.getItems().get(1).getId()),
                                "Retry must not create another order"
                        ))
                )
        );
        assertEquals(2, retryResponse.orders().size());
        assertEquals(70_000L, retryResponse.totalPrice());
        assertEquals(2, orderRepository.findByMenuAndBeneficiaryAndStatusOrderByCreatedAtAsc(
                menu,
                user,
                LunchOrderStatus.ACTIVE
        ).size());
        assertEquals(70_000L, account.getDebt());
        assertEquals(2, transactionRepository.findByAccountOrderByCreatedAtDesc(account).size());

        SummaryResponse summary = lunchAdminService.summarize(user, menu.getId());
        assertEquals(2, summary.totalOrders());
        assertEquals(70_000L, summary.totalAmount());
        assertTrue(summary.orderText().contains(": 2 phần"));
    }

    @Test
    void adminCanReplaceOrDeleteDraftMenuButCannotChangeMenuWithOrders() {
        User admin = saveUser("menu-editor");
        LunchMenu draft = saveMenu(admin, LocalDate.of(2099, 1, 18));
        draft.setStatus(LunchMenuStatus.CLOSED);
        menuRepository.saveAndFlush(draft);

        var updated = lunchAdminService.updateMenu(
                admin,
                draft.getId(),
                new UpdateMenuRequest(
                        draft.getMenuDate(),
                        "Vũ - bản đã sửa",
                        "Quán mới",
                        draft.getMenuDate().atTime(11, 0),
                        40_000L,
                        "Gà kho\nCá chiên\n+\nBún bò"
                )
        );

        assertEquals(draft.getId(), updated.id());
        assertEquals("Vũ - bản đã sửa", updated.orderLabel());
        assertEquals(2, updated.regularItems().size());
        assertEquals(1, updated.specialItems().size());
        assertEquals(40_000L, updated.price());
        assertEquals("OPEN", updated.status());
        assertTrue(updated.canReplace());

        LunchMenu removable = saveMenu(admin, LocalDate.of(2099, 1, 19));
        lunchAdminService.deleteMenu(admin, removable.getId());
        assertFalse(menuRepository.existsById(removable.getId()));

        lunchService.createOrder(admin, comboRequest(draft, null));
        assertThrows(
                ConflictException.class,
                () -> lunchAdminService.updateMenu(
                        admin,
                        draft.getId(),
                        new UpdateMenuRequest(
                                draft.getMenuDate(),
                                "Không được lưu",
                                "Quán mới",
                                draft.getMenuDate().atTime(11, 0),
                                40_000L,
                                "Gà kho\nCá chiên\n+\nBún bò"
                        )
                )
        );
    }

    @Test
    void batchRejectsNullPortionWithBadRequestInsteadOfServerError() {
        User user = saveUser("invalid-batch-user");
        LunchMenu menu = saveMenu(user, LocalDate.of(2099, 1, 20));

        assertThrows(
                IllegalArgumentException.class,
                () -> lunchService.createOrderBatch(
                        user,
                        new CreateOrderBatchRequest(
                                menu.getId(),
                                "invalid-batch-123456",
                                Collections.singletonList(null)
                        )
                )
        );
    }

    private User saveUser(String prefix) {
        return userRepository.save(User.builder()
                .email(prefix + "-" + UUID.randomUUID() + "@example.com")
                .password("encoded")
                .fullName(prefix)
                .role("USER")
                .build());
    }

    private LunchMenu saveMenu(User creator, LocalDate date) {
        LunchMenu menu = LunchMenu.builder()
                .menuDate(date)
                .orderLabel("Vũ")
                .vendorName("Quán cơm")
                .cutoffAt(date.atTime(10, 30))
                .price(35_000L)
                .status(LunchMenuStatus.OPEN)
                .rawMenuText("Sườn ram\nThịt kho\n+\nPhở bò")
                .createdBy(creator)
                .build();
        menu.getItems().add(LunchMenuItem.builder()
                .menu(menu)
                .name("Sườn ram")
                .type(LunchMenuItemType.REGULAR)
                .sortOrder(0)
                .build());
        menu.getItems().add(LunchMenuItem.builder()
                .menu(menu)
                .name("Thịt kho")
                .type(LunchMenuItemType.REGULAR)
                .sortOrder(1)
                .build());
        menu.getItems().add(LunchMenuItem.builder()
                .menu(menu)
                .name("Phở bò")
                .type(LunchMenuItemType.SPECIAL)
                .sortOrder(2)
                .build());
        return menuRepository.saveAndFlush(menu);
    }

    private CreateOrderRequest comboRequest(
            LunchMenu menu,
            String beneficiaryUserId
    ) {
        return new CreateOrderRequest(
                menu.getId(),
                beneficiaryUserId,
                LunchSelectionType.COMBO,
                List.of(
                        menu.getItems().get(0).getId(),
                        menu.getItems().get(1).getId()
                ),
                null
        );
    }
}
