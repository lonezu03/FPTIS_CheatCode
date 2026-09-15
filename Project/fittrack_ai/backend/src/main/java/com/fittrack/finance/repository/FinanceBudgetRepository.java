package com.fittrack.finance.repository;
import com.fittrack.finance.entity.FinanceBudget;
import com.fittrack.user.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import java.time.LocalDate;
import java.util.*;
public interface FinanceBudgetRepository extends JpaRepository<FinanceBudget,String>{
    List<FinanceBudget> findByUserAndMonthStartOrderByCategoryNameAsc(User user, LocalDate monthStart);
    Optional<FinanceBudget> findByIdAndUser(String id, User user);
    Optional<FinanceBudget> findByUserAndCategoryIdAndMonthStart(User user,String categoryId,LocalDate monthStart);
}
