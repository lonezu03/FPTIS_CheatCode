package com.fittrack.finance.service;

import com.fittrack.FittrackBackendApplication;
import com.fittrack.common.exception.ConflictException;
import com.fittrack.common.exception.ResourceNotFoundException;
import com.fittrack.finance.dto.FinanceDtos.ReconcileRequest;
import com.fittrack.finance.entity.*;
import com.fittrack.finance.repository.*;
import com.fittrack.user.entity.User;
import com.fittrack.user.repository.UserRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;
import static org.assertj.core.api.Assertions.*;

@SpringBootTest(classes = FittrackBackendApplication.class)
@ActiveProfiles("test") @Transactional
class FinanceReconciliationIntegrationTest {
    @Autowired FinanceReconciliationService reconciliation;
    @Autowired FinanceService finance;
    @Autowired UserRepository users;
    @Autowired FinanceAccountRepository accounts;
    @Autowired FinanceTransactionRepository transactions;

    @Test
    void reconcilesActualBalanceWithoutChangingReportsOrTransactionsAndKeepsAudit() {
        var user = user();
        var bank = account(user, "Ngân hàng");
        var cash = account(user, "Tiền mặt");
        tx(user, bank, null, "INCOME", "200000", "POSTED");
        tx(user, bank, null, "EXPENSE", "100000", "POSTED");
        tx(user, bank, cash, "TRANSFER", "50000", "POSTED");
        tx(user, bank, null, "EXPENSE", "999999", "VOID");
        var reportBefore = finance.report(user, LocalDate.now());
        var count = transactions.count();
        var result = reconciliation.reconcile(user, bank.getId(), request("350000", "1050000"));
        assertThat(result.difference()).isEqualByComparingTo("-700000");
        assertThat(result.balanceBefore()).isEqualByComparingTo("1050000");
        assertThat(balance(user, bank)).isEqualByComparingTo("350000");
        assertThat(bank.getOpeningBalance()).isEqualByComparingTo("300000");
        assertThat(balance(user, cash)).isEqualByComparingTo("1050000");
        assertThat(transactions.count()).isEqualTo(count);
        var reportAfter = finance.report(user, LocalDate.now());
        assertThat(reportAfter.income()).isEqualByComparingTo(reportBefore.income());
        assertThat(reportAfter.expense()).isEqualByComparingTo(reportBefore.expense());
        assertThat(reconciliation.history(user, bank.getId(), 0, 10).totalElements()).isEqualTo(1);
    }

    @Test
    void allowsZeroAndNegativeActualBalancesAndRejectsDuplicateStaleSubmission() {
        var user = user(); var account = account(user, "Ví");
        reconciliation.reconcile(user, account.getId(), request("0", "1000000"));
        assertThat(balance(user, account)).isZero();
        assertThatThrownBy(() -> reconciliation.reconcile(user, account.getId(), request("0", "1000000")))
                .isInstanceOf(ConflictException.class);
        reconciliation.reconcile(user, account.getId(), request("-200000", "0"));
        assertThat(balance(user, account)).isEqualByComparingTo("-200000");
        assertThat(reconciliation.history(user, account.getId(), 0, 10).totalElements()).isEqualTo(2);
    }

    @Test
    void ownerScopeAppliesToReadAndWriteEvenForAdminAndArchivedWalletsCannotChange() {
        var owner = user(); var account = account(owner, "Riêng tư");
        var other = user(); other.setRole("ADMIN");
        assertThatThrownBy(() -> reconciliation.reconcile(other, account.getId(), request("0", "1000000")))
                .isInstanceOf(ResourceNotFoundException.class);
        assertThatThrownBy(() -> reconciliation.history(other, account.getId(), 0, 10))
                .isInstanceOf(ResourceNotFoundException.class);
        account.setActive(false); accounts.saveAndFlush(account);
        assertThatThrownBy(() -> reconciliation.reconcile(owner, account.getId(), request("0", "1000000")))
                .isInstanceOf(IllegalArgumentException.class);
        assertThat(balance(owner, account)).isEqualByComparingTo("1000000");
    }

    @Test
    void unchangedAmountMissingNoteAndExcessPrecisionDoNotChangeBalance() {
        var user = user(); var account = account(user, "Ví");
        assertThatThrownBy(() -> reconciliation.reconcile(user, account.getId(), request("1000000", "1000000"))).isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> reconciliation.reconcile(user, account.getId(), new ReconcileRequest(BigDecimal.ZERO, new BigDecimal("1000000"), " "))).isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> reconciliation.reconcile(user, account.getId(), request("1.001", "1000000"))).isInstanceOf(IllegalArgumentException.class);
        assertThat(balance(user, account)).isEqualByComparingTo("1000000");
    }

    private ReconcileRequest request(String actual, String expected) { return new ReconcileRequest(new BigDecimal(actual), new BigDecimal(expected), "Đối soát thực tế"); }
    private BigDecimal balance(User user, FinanceAccount account) { return finance.accounts(user).stream().filter(a -> a.id().equals(account.getId())).findFirst().orElseThrow().currentBalance(); }
    private User user() { return users.saveAndFlush(User.builder().email(UUID.randomUUID()+"@example.test").password("test").role("USER").financeEnabled(true).build()); }
    private FinanceAccount account(User user, String name) { return accounts.saveAndFlush(FinanceAccount.builder().user(user).name(name).accountType("BANK").currencyCode("VND").openingBalance(new BigDecimal("1000000")).active(true).build()); }
    private void tx(User user, FinanceAccount account, FinanceAccount destination, String type, String amount, String status) {
        transactions.saveAndFlush(FinanceTransaction.builder().user(user).account(account).destinationAccount(destination).type(type).amount(new BigDecimal(amount)).status(status).occurredAt(LocalDate.now().atTime(12,0)).build());
    }
}
