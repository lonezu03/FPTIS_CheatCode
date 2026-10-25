package com.fittrack.finance.repository;

import com.fittrack.finance.entity.FinanceBalanceReconciliation;
import com.fittrack.user.entity.User;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

public interface FinanceBalanceReconciliationRepository extends JpaRepository<FinanceBalanceReconciliation, String> {
    Page<FinanceBalanceReconciliation> findByUserAndAccountId(User user, String accountId, Pageable pageable);
}
