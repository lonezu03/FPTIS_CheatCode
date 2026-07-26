package com.fittrack.lunch.service;

import com.fittrack.FittrackBackendApplication;
import com.fittrack.common.exception.ConflictException;
import com.fittrack.lunch.dto.LunchDtos.CreateOrderRequest;
import com.fittrack.lunch.dto.LunchDtos.ConfirmExternalPaymentRequest;
import com.fittrack.lunch.dto.LunchDtos.OrderResponse;
import com.fittrack.lunch.dto.LunchDtos.SummaryResponse;
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
    private UserRepository userRepository;

    @Autowired
    private LunchMenuRepository menuRepository;

    @Autowired
    private LunchOrderRepository orderRepository;

    @Autowired
    private LunchFundAccountRepository accountRepository;

    @Autowired
    private LunchFundTransactionRepository transactionRepository;

    @Test
    void selfOrderWithInsufficientFundIsCreatedUnpaidWithoutNegativeBalance() {
        User user = saveUser("self-unpaid");
        LunchMenu menu = saveMenu(user, LocalDate.of(2099, 1, 10));

        OrderResponse response = lunchService.createOrder(
                user,
                comboRequest(menu, null)
        );

        assertEquals("UNPAID", response.paymentStatus());
        assertNull(response.payer());
        assertEquals(0L, accountRepository.findByUser(user)
                .map(LunchFundAccount::getBalance)
                .orElse(0L));
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
    void priorUnpaidOrderBlocksTheBeneficiaryFromOrderingForSelfNextDay() {
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

        ConflictException exception = assertThrows(
                ConflictException.class,
                () -> lunchService.createOrder(user, comboRequest(nextMenu, null))
        );

        assertTrue(exception.getMessage().contains("chưa thanh toán"));
    }

    @Test
    void externalPaymentConfirmationDoesNotChangeTheWallet() {
        User admin = saveUser("external-admin");
        User user = saveUser("external-user");
        LunchMenu menu = saveMenu(admin, LocalDate.of(2099, 1, 15));
        LunchFundAccount account = accountRepository.save(
                LunchFundAccount.builder()
                        .user(user)
                        .balance(10_000L)
                        .build()
        );
        OrderResponse unpaidOrder = lunchService.createOrder(
                user,
                comboRequest(menu, null)
        );

        OrderResponse confirmed = lunchAdminService.confirmExternalPayment(
                admin,
                unpaidOrder.id(),
                new ConfirmExternalPaymentRequest("Đã nhận chuyển khoản")
        );

        assertEquals("PAID_EXTERNAL", confirmed.paymentStatus());
        assertEquals(10_000L, account.getBalance());
        assertTrue(transactionRepository
                .findByAccountOrderByCreatedAtDesc(account)
                .isEmpty());
    }

    @Test
    void summarizeClosesMenuAndStoresExactSnapshotThatCannotBeReopened() {
        User admin = saveUser("summary-admin");
        LunchMenu menu = saveMenu(admin, LocalDate.of(2099, 1, 14));
        lunchService.createOrder(admin, comboRequest(menu, null));

        SummaryResponse summary = lunchAdminService.summarize(admin, menu.getId());

        assertEquals(1, summary.totalOrders());
        assertEquals(1, summary.unpaidOrders());
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
        assertThrows(
                ConflictException.class,
                () -> lunchAdminService.reopenMenu(menu.getId())
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
