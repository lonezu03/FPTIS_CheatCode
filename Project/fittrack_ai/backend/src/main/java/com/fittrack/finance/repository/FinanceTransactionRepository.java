package com.fittrack.finance.repository;
import com.fittrack.finance.entity.FinanceTransaction;
import com.fittrack.user.entity.User;
import org.springframework.data.domain.*;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;
import java.time.LocalDateTime;
import java.util.*;
public interface FinanceTransactionRepository extends JpaRepository<FinanceTransaction,String>{
    Optional<FinanceTransaction> findByIdAndUser(String id, User user);
    List<FinanceTransaction> findByUserAndOccurredAtBetweenAndStatus(User user, LocalDateTime from, LocalDateTime to, String status);
    List<FinanceTransaction> findByUserAndStatus(User user, String status);
    @Query("""
      select t from FinanceTransaction t where t.user=:user
      and (:from is null or t.occurredAt>=:from) and (:to is null or t.occurredAt<:to)
      and (:accountId is null or t.account.id=:accountId or t.destinationAccount.id=:accountId)
      and (:categoryId is null or t.category.id=:categoryId)
      and (:type is null or t.type=:type)
      and (:q is null or lower(coalesce(t.merchant,'')) like lower(concat('%',:q,'%')) or lower(coalesce(t.note,'')) like lower(concat('%',:q,'%')))
      order by t.occurredAt desc, t.createdAt desc
      """)
    Page<FinanceTransaction> search(@Param("user") User user,@Param("from") LocalDateTime from,@Param("to") LocalDateTime to,
       @Param("accountId") String accountId,@Param("categoryId") String categoryId,@Param("type") String type,@Param("q") String q,Pageable pageable);
}
