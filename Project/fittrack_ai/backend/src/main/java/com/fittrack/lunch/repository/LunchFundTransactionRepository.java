package com.fittrack.lunch.repository;

import com.fittrack.lunch.entity.LunchFundAccount;
import com.fittrack.lunch.entity.LunchFundTransaction;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface LunchFundTransactionRepository extends JpaRepository<LunchFundTransaction, String> {

    List<LunchFundTransaction> findByAccountOrderByCreatedAtDesc(LunchFundAccount account);
}
