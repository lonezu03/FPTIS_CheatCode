package com.fittrack.finance.repository;
import com.fittrack.finance.entity.FinanceRecurringRule;
import com.fittrack.user.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import java.time.LocalDate;
import java.util.*;
public interface FinanceRecurringRuleRepository extends JpaRepository<FinanceRecurringRule,String>{
    List<FinanceRecurringRule> findByUserOrderByActiveDescNextDueDateAsc(User user);
    Optional<FinanceRecurringRule> findByIdAndUser(String id, User user);
    List<FinanceRecurringRule> findByActiveTrueAndNextDueDateLessThanEqual(LocalDate date);
}
