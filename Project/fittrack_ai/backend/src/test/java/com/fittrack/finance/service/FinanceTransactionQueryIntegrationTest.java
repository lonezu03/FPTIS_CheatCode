package com.fittrack.finance.service;

import com.fittrack.FittrackBackendApplication;
import com.fittrack.finance.entity.FinanceAccount;
import com.fittrack.finance.entity.FinanceCategory;
import com.fittrack.finance.entity.FinanceTransaction;
import com.fittrack.finance.repository.FinanceAccountRepository;
import com.fittrack.finance.repository.FinanceCategoryRepository;
import com.fittrack.finance.repository.FinanceTransactionRepository;
import com.fittrack.user.entity.User;
import com.fittrack.user.repository.UserRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;

@SpringBootTest(classes = FittrackBackendApplication.class)
@ActiveProfiles("test")
@Transactional
class FinanceTransactionQueryIntegrationTest {

    @Autowired private FinanceService financeService;
    @Autowired private UserRepository userRepository;
    @Autowired private FinanceAccountRepository accountRepository;
    @Autowired private FinanceCategoryRepository categoryRepository;
    @Autowired private FinanceTransactionRepository transactionRepository;

    @Test
    void listsMonthlyTransactionsWhenAllOptionalFiltersAreMissing() {
        User owner = userRepository.save(User.builder()
                .email("finance-query-" + UUID.randomUUID() + "@example.com")
                .password("encoded")
                .fullName("Finance query regression")
                .financeEnabled(true)
                .build());
        FinanceAccount account = accountRepository.save(FinanceAccount.builder()
                .user(owner)
                .name("Tiền mặt")
                .accountType("CASH")
                .currencyCode("VND")
                .openingBalance(BigDecimal.ZERO)
                .active(true)
                .build());
        FinanceCategory category = categoryRepository.save(FinanceCategory.builder()
                .user(owner)
                .name("Ăn uống")
                .transactionKind("EXPENSE")
                .expenseNature("ESSENTIAL_VARIABLE")
                .active(true)
                .systemCategory(false)
                .build());
        transactionRepository.save(FinanceTransaction.builder()
                .user(owner)
                .account(account)
                .category(category)
                .expenseNature("ESSENTIAL_VARIABLE")
                .type("EXPENSE")
                .amount(BigDecimal.valueOf(85_000))
                .occurredAt(LocalDateTime.of(2026, 9, 15, 12, 0))
                .merchant("Quán cơm")
                .note("Bữa trưa")
                .status("POSTED")
                .build());
        transactionRepository.save(FinanceTransaction.builder()
                .user(owner)
                .account(account)
                .category(category)
                .expenseNature("ESSENTIAL_VARIABLE")
                .type("EXPENSE")
                .amount(BigDecimal.valueOf(45_000))
                .occurredAt(LocalDateTime.of(2026, 8, 31, 23, 59))
                .status("POSTED")
                .build());

        var page = financeService.transactions(
                owner,
                LocalDate.of(2026, 9, 1),
                LocalDate.of(2026, 9, 30),
                null,
                null,
                null,
                null,
                0,
                15
        );

        assertEquals(1, page.totalElements());
        assertEquals("Quán cơm", page.content().getFirst().merchant());
    }

    @Test
    void combinesAccountCategoryTypeAndTextFilters() {
        User owner = userRepository.save(User.builder()
                .email("finance-filter-" + UUID.randomUUID() + "@example.com")
                .password("encoded")
                .financeEnabled(true)
                .build());
        FinanceAccount account = accountRepository.save(FinanceAccount.builder()
                .user(owner).name("Ngân hàng").accountType("BANK").currencyCode("VND")
                .openingBalance(BigDecimal.ZERO).active(true).build());
        FinanceCategory category = categoryRepository.save(FinanceCategory.builder()
                .user(owner).name("Di chuyển").transactionKind("EXPENSE")
                .expenseNature("ESSENTIAL_VARIABLE").active(true).systemCategory(false).build());
        transactionRepository.save(FinanceTransaction.builder()
                .user(owner).account(account).category(category).expenseNature("ESSENTIAL_VARIABLE")
                .type("EXPENSE").amount(BigDecimal.valueOf(50_000))
                .occurredAt(LocalDateTime.of(2026, 9, 10, 8, 30))
                .merchant("Grab").note("Đi làm").status("POSTED").build());

        var page = financeService.transactions(owner, null, null, account.getId(), category.getId(), "expense", "đi làm", 0, 15);

        assertEquals(1, page.totalElements());
        assertEquals("EXPENSE", page.content().getFirst().type());
    }
}
