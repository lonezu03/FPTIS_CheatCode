package com.fittrack.finance.repository;
import com.fittrack.finance.entity.FinanceAccount;
import com.fittrack.user.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.*;
public interface FinanceAccountRepository extends JpaRepository<FinanceAccount,String>{
    List<FinanceAccount> findByUserOrderByActiveDescCreatedAtAsc(User user);
    Optional<FinanceAccount> findByIdAndUser(String id, User user);
}
