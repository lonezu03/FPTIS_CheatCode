package com.fittrack.finance.service;

import com.fittrack.finance.dto.FinanceDtos.TransactionRequest;
import com.fittrack.finance.entity.FinanceAccount;
import com.fittrack.finance.entity.FinanceCategory;
import com.fittrack.finance.entity.FinanceTransaction;
import com.fittrack.finance.repository.*;
import com.fittrack.lunch.service.LunchNotificationService;
import com.fittrack.user.entity.User;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

class FinanceServiceTest {
    @Mock FinanceAccountRepository accounts;
    @Mock FinanceCategoryRepository categories;
    @Mock FinanceTransactionRepository transactions;
    @Mock FinanceBudgetRepository budgets;
    @Mock FinanceRecurringRuleRepository recurring;
    @Mock LunchNotificationService notifications;

    private FinanceService service;
    private User user;
    private FinanceAccount bank;
    private FinanceAccount cash;
    private FinanceCategory food;

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
        service = new FinanceService(accounts, categories, transactions, budgets, recurring, notifications);
        user = User.builder().id("user-1").role("USER").active(true).financeEnabled(true).build();
        bank = account("bank", "Ngân hàng");
        cash = account("cash", "Tiền mặt");
        food = FinanceCategory.builder().id("food").user(user).name("Ăn uống")
                .transactionKind("EXPENSE").expenseNature("ESSENTIAL_VARIABLE").active(true).build();
        when(accounts.findByIdAndUser("bank", user)).thenReturn(Optional.of(bank));
        when(accounts.findByIdAndUser("cash", user)).thenReturn(Optional.of(cash));
        when(categories.findByIdAndUser("food", user)).thenReturn(Optional.of(food));
        when(budgets.findByUserAndMonthStartOrderByCategoryNameAsc(any(), any())).thenReturn(List.of());
        when(transactions.save(any())).thenAnswer(invocation -> invocation.getArgument(0));
    }

    @Test
    void expenseNatureCanOverrideCategoryForAccurateClassification() {
        var result = service.createTransaction(user, new TransactionRequest(
                "EXPENSE", BigDecimal.valueOf(85_000), "bank", null, "food",
                "DISCRETIONARY", LocalDateTime.of(2026, 9, 15, 12, 0), "Quán cà phê", null
        ));

        assertEquals("DISCRETIONARY", result.expenseNature());
        assertEquals("food", result.categoryId());
    }

    @Test
    void transferIsExcludedFromIncomeAndExpenseReport() {
        LocalDateTime at = LocalDateTime.of(2026, 9, 15, 12, 0);
        var income = transaction("income", "INCOME", 10_000_000, bank, null, null, at);
        var expense = transaction("expense", "EXPENSE", 2_000_000, bank, null, food, at);
        var transfer = transaction("transfer", "TRANSFER", 1_000_000, bank, cash, null, at);
        when(transactions.findByUserAndOccurredAtBetweenAndStatus(
                user, LocalDate.of(2026, 9, 1).atStartOfDay(), LocalDate.of(2026, 10, 1).atStartOfDay(), "POSTED"
        )).thenReturn(List.of(income, expense, transfer));
        when(transactions.findByUserAndOccurredAtBetweenAndStatus(
                user, LocalDate.of(2026, 8, 1).atStartOfDay(), LocalDate.of(2026, 9, 1).atStartOfDay(), "POSTED"
        )).thenReturn(List.of());

        var report = service.report(user, LocalDate.of(2026, 9, 20));

        assertEquals(0, report.income().compareTo(BigDecimal.valueOf(10_000_000)));
        assertEquals(0, report.expense().compareTo(BigDecimal.valueOf(2_000_000)));
        assertEquals(0, report.netSaving().compareTo(BigDecimal.valueOf(8_000_000)));
    }

    @Test
    void transferRequiresDifferentAccounts() {
        var request = new TransactionRequest(
                "TRANSFER", BigDecimal.valueOf(500_000), "bank", "bank", null,
                null, LocalDateTime.now(), null, null
        );

        var error = assertThrows(IllegalArgumentException.class,
                () -> service.createTransaction(user, request));

        assertTrue(error.getMessage().contains("khác tài khoản nguồn"));
    }

    private FinanceAccount account(String id, String name) {
        return FinanceAccount.builder().id(id).user(user).name(name).accountType("BANK")
                .currencyCode("VND").openingBalance(BigDecimal.ZERO).active(true).build();
    }

    private FinanceTransaction transaction(String id, String type, long amount, FinanceAccount source,
                                           FinanceAccount destination, FinanceCategory category, LocalDateTime at) {
        return FinanceTransaction.builder().id(id).user(user).type(type).amount(BigDecimal.valueOf(amount))
                .account(source).destinationAccount(destination).category(category)
                .expenseNature(category == null ? null : category.getExpenseNature())
                .occurredAt(at).status("POSTED").build();
    }
}
