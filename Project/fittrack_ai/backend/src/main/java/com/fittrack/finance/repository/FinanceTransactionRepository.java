package com.fittrack.finance.repository;
import com.fittrack.finance.entity.FinanceTransaction;
import com.fittrack.user.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import java.time.LocalDateTime;
import java.util.*;
public interface FinanceTransactionRepository extends JpaRepository<FinanceTransaction,String>, JpaSpecificationExecutor<FinanceTransaction>{
    @org.springframework.data.jpa.repository.Query("select count(t)>0 from FinanceTransaction t left join t.destinationAccount destination where t.user=:user and (t.account.id=:accountId or destination.id=:accountId)")
    boolean hasAccountHistory(@org.springframework.data.repository.query.Param("user") User user,@org.springframework.data.repository.query.Param("accountId") String accountId);
    Optional<FinanceTransaction> findByIdAndUser(String id, User user);
    List<FinanceTransaction> findByUserAndOccurredAtBetweenAndStatus(User user, LocalDateTime from, LocalDateTime to, String status);
    List<FinanceTransaction> findByUserAndStatus(User user, String status);
}
