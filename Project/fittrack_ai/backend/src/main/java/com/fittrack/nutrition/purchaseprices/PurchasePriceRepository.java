package com.fittrack.nutrition.purchaseprices;
import com.fittrack.user.entity.User;
import jakarta.persistence.LockModeType;
import org.springframework.data.domain.*;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;
import java.time.LocalDate;
import java.util.*;
public interface PurchasePriceRepository extends JpaRepository<PurchasePrice,String> {
 @EntityGraph(attributePaths="food") @Query("select p from PurchasePrice p where p.user=:user and p.active=:active and (:foodId is null or p.food.id=:foodId) order by p.purchasedOn desc,p.createdAt desc,p.id")
 Page<PurchasePrice> list(@Param("user")User user,@Param("active")boolean active,@Param("foodId")String foodId,Pageable page);
 @Lock(LockModeType.PESSIMISTIC_WRITE) @Query("select p from PurchasePrice p join fetch p.food where p.id=:id and p.user=:user") Optional<PurchasePrice> lock(@Param("id")String id,@Param("user")User user);
 Optional<PurchasePrice> findByUserAndOperationId(User user,String operationId);
 @EntityGraph(attributePaths="food") @Query("select p from PurchasePrice p where p.user=:user and p.active=true and p.food.id in :ids and p.purchasedOn<=:reference and not exists (select q.id from PurchasePrice q where q.user=p.user and q.food=p.food and q.unit=p.unit and q.active=true and q.purchasedOn<=:reference and (q.purchasedOn>p.purchasedOn or (q.purchasedOn=p.purchasedOn and q.createdAt>p.createdAt) or (q.purchasedOn=p.purchasedOn and q.createdAt=p.createdAt and q.id>p.id))) order by p.purchasedOn desc,p.createdAt desc,p.id desc")
 List<PurchasePrice> candidates(@Param("user")User user,@Param("ids")Set<String> ids,@Param("reference")LocalDate reference);
}
