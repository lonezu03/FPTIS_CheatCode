package com.fittrack.finance.repository;
import com.fittrack.finance.entity.FinanceTransaction;
import com.fittrack.user.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import java.time.LocalDateTime;
import java.util.*;
public interface FinanceTransactionRepository extends JpaRepository<FinanceTransaction,String>, JpaSpecificationExecutor<FinanceTransaction>{
    Optional<FinanceTransaction> findByIdAndUser(String id, User user);
    List<FinanceTransaction> findByUserAndOccurredAtBetweenAndStatus(User user, LocalDateTime from, LocalDateTime to, String status);
    List<FinanceTransaction> findByUserAndStatus(User user, String status);
}
