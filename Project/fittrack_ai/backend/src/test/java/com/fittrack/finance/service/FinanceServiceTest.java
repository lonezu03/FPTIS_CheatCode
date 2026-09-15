package com.fittrack.finance.service;

import com.fittrack.finance.dto.FinanceDtos.CategoryRequest;
import com.fittrack.finance.dto.FinanceDtos.TransactionRequest;
import com.fittrack.finance.entity.FinanceAccount;
import com.fittrack.finance.entity.FinanceCategory;
import com.fittrack.finance.entity.FinanceRecurringRule;
import com.fittrack.finance.entity.FinanceTransaction;
import com.fittrack.finance.repository.*;
import com.fittrack.lunch.service.LunchNotificationService;
import com.fittrack.user.entity.User;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.mockito.ArgumentCaptor;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.mockito.Mockito.atLeastOnce;

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
        when(recurring.save(any())).thenAnswer(invocation -> invocation.getArgument(0));
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

    @Test
    void archivedAccountAlsoStopsItsActiveRecurringRules() {
        var rule = FinanceRecurringRule.builder()
                .id("rent-rule")
                .user(user)
                .account(bank)
                .active(true)
                .build();
        when(recurring.findByUserOrderByActiveDescNextDueDateAsc(user)).thenReturn(List.of(rule));

        service.archiveAccount(user, bank.getId());

        assertFalse(bank.getActive());
        assertFalse(rule.getActive());
        verify(accounts).save(bank);
    }

    @Test
    void categoryParentMustUseTheSameTransactionKind() {
        var incomeParent = FinanceCategory.builder()
                .id("salary")
                .user(user)
                .name("Lương")
                .transactionKind("INCOME")
                .active(true)
                .build();
        when(categories.findByIdAndUser("salary", user)).thenReturn(Optional.of(incomeParent));

        var error = assertThrows(IllegalArgumentException.class, () -> service.createCategory(
                user,
                new CategoryRequest("Ăn trưa", "EXPENSE", "ESSENTIAL_VARIABLE", "salary", null)
        ));

        assertTrue(error.getMessage().contains("cùng loại thu hoặc chi"));
    }

    @Test
    void voidTransactionCannotBeRestoredByEditing() {
        var value = transaction(
                "void-expense", "EXPENSE", 100_000, bank, null, food, LocalDateTime.now()
        );
        value.setStatus("VOID");
        when(transactions.findByIdAndUser(value.getId(), user)).thenReturn(Optional.of(value));

        var request = new TransactionRequest(
                "EXPENSE", BigDecimal.valueOf(120_000), "bank", null, "food",
                "ESSENTIAL_VARIABLE", LocalDateTime.now(), null, null
        );

        var error = assertThrows(IllegalArgumentException.class,
                () -> service.updateTransaction(user, value.getId(), request));

        assertTrue(error.getMessage().contains("đã hủy"));
    }

    @Test
    void snoozeClearsTheNotificationGateWithoutPostingATransaction() {
        var rule = FinanceRecurringRule.builder()
                .id("internet-rule")
                .user(user)
                .account(bank)
                .name("Internet")
                .transactionType("EXPENSE")
                .category(food)
                .expenseNature("FIXED_MANDATORY")
                .amount(BigDecimal.valueOf(220_000))
                .frequency("MONTHLY")
                .nextDueDate(LocalDate.of(2026, 9, 20))
                .remindDaysBefore(1)
                .lastNotifiedFor(LocalDate.of(2026, 9, 20))
                .active(true)
                .build();
        when(recurring.findByIdAndUser(rule.getId(), user)).thenReturn(Optional.of(rule));

        var response = service.snoozeRecurring(user, rule.getId());

        assertNull(rule.getLastNotifiedFor());
        assertEquals("internet-rule", response.id());
        verify(recurring).save(rule);
    }

    @Test
    void defaultCategoriesIncludeVietnameseSubcategories() {
        when(categories.findByUserOrderByTransactionKindAscNameAsc(user)).thenReturn(List.of());
        when(categories.save(any())).thenAnswer(invocation -> {
            FinanceCategory category = invocation.getArgument(0);
            category.setId("seed-" + category.getName());
            return category;
        });

        service.categories(user);

        var captor = ArgumentCaptor.forClass(FinanceCategory.class);
        verify(categories, atLeastOnce()).save(captor.capture());
        var cafe = captor.getAllValues().stream()
                .filter(category -> "Cafe".equals(category.getName()))
                .findFirst()
                .orElseThrow();
        assertNotNull(cafe.getParent());
        assertEquals("Ăn uống", cafe.getParent().getName());
        assertEquals("DISCRETIONARY", cafe.getExpenseNature());
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
