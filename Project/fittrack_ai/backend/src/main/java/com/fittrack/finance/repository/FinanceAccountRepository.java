package com.fittrack.finance.repository;
import com.fittrack.finance.entity.FinanceAccount;
import com.fittrack.user.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.*;
public interface FinanceAccountRepository extends JpaRepository<FinanceAccount,String>{
    @org.springframework.data.jpa.repository.Lock(jakarta.persistence.LockModeType.PESSIMISTIC_WRITE)
    @org.springframework.data.jpa.repository.Query("select a from FinanceAccount a where a.user = :user order by a.id")
    List<FinanceAccount> lockByOwner(@org.springframework.data.repository.query.Param("user") User user);
    List<FinanceAccount> findByUserOrderByActiveDescCreatedAtAsc(User user);
    Optional<FinanceAccount> findByIdAndUser(String id, User user);
}
