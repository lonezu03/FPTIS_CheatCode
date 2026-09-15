package com.fittrack.finance.repository;
import com.fittrack.finance.entity.FinanceCategory;
import com.fittrack.user.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.*;
public interface FinanceCategoryRepository extends JpaRepository<FinanceCategory,String>{
    List<FinanceCategory> findByUserOrderByTransactionKindAscNameAsc(User user);
    Optional<FinanceCategory> findByIdAndUser(String id, User user);
    boolean existsByUser(User user);
}
