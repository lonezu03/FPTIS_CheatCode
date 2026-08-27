package com.fittrack.lunch.service;

import com.fittrack.lunch.entity.*;
import com.fittrack.lunch.repository.LunchFundAccountRepository;
import com.fittrack.lunch.repository.LunchFundTransactionRepository;
import com.fittrack.user.entity.User;
import com.fittrack.lunch.dto.LunchDtos.FundAdjustmentAction;
import com.fittrack.user.repository.UserRepository;
import com.fittrack.common.exception.ConflictException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class LunchAccountService {

    private final LunchFundAccountRepository accountRepository;
    private final LunchFundTransactionRepository transactionRepository;
    private final UserRepository userRepository;

    @Transactional(readOnly = true)
    public long netBalance(User user) {
        return accountRepository.findByUser(user)
                .map(this::netBalance)
                .orElse(0L);
    }

    public long netBalance(LunchFundAccount account) {
        return Math.subtractExact(
                account.getBalance() == null ? 0L : account.getBalance(),
                account.getDebt() == null ? 0L : account.getDebt()
        );
    }

    public long outstandingDebt(User user) {
        return accountRepository.findByUser(user)
                .map(account -> account.getDebt() == null ? 0L : account.getDebt())
                .orElse(0L);
    }

    @Transactional
    public LunchFundTransaction debitOrder(
            User payer,
            long amount,
            LunchOrder order,
            User actor,
            String note,
            boolean allowDebt
    ) {
        LunchFundAccount account = getOrCreateForUpdate(payer);
        long balance = account.getBalance();
        long debt = account.getDebt();

        if (!allowDebt && netBalance(account) < amount) {
            throw new ConflictException("Số dư quỹ của bạn không đủ để trả hộ");
        }

        if (balance >= amount) {
            account.setBalance(Math.subtractExact(balance, amount));
        } else {
            long shortfall = Math.subtractExact(amount, balance);
            account.setBalance(0L);
            account.setDebt(Math.addExact(debt, shortfall));
        }

        return saveTransaction(
                account,
                LunchFundTransactionType.ORDER_DEBIT,
                -amount,
                order,
                actor,
                note
        );
    }

    @Transactional
    public LunchFundTransaction adjust(
            User user,
            long amount,
            FundAdjustmentAction action,
            User actor,
            String note
    ) {
        LunchFundAccount account = getOrCreateForUpdate(user);
        long signedAmount;
        switch (action) {
            case ADD_FUND -> {
                account.setBalance(Math.addExact(account.getBalance(), amount));
                signedAmount = amount;
            }
            case REMOVE_FUND -> {
                if (account.getBalance() < amount) {
                    throw new ConflictException("Số dư quỹ không đủ để trừ khoản này");
                }
                account.setBalance(Math.subtractExact(account.getBalance(), amount));
                signedAmount = -amount;
            }
            case ADD_DEBT -> {
                account.setDebt(Math.addExact(account.getDebt(), amount));
                signedAmount = -amount;
            }
            case REMOVE_DEBT -> {
                if (account.getDebt() < amount) {
                    throw new ConflictException("Số công nợ không đủ để giảm khoản này");
                }
                account.setDebt(Math.subtractExact(account.getDebt(), amount));
                signedAmount = amount;
            }
            default -> throw new IllegalArgumentException("Loại điều chỉnh không hợp lệ");
        }
        return saveTransaction(account, LunchFundTransactionType.ADMIN_ADJUSTMENT, signedAmount, null, actor, note);
    }

    @Transactional
    public LunchFundTransaction credit(
            User user,
            long amount,
            LunchFundTransactionType type,
            LunchOrder order,
            User actor,
            String note
    ) {
        LunchFundAccount account = getOrCreateForUpdate(user);
        long debtPayment = Math.min(account.getDebt(), amount);
        account.setDebt(Math.subtractExact(account.getDebt(), debtPayment));
        long remainder = Math.subtractExact(amount, debtPayment);
        if (remainder > 0) {
            account.setBalance(Math.addExact(account.getBalance(), remainder));
        }

        return saveTransaction(account, type, amount, order, actor, note);
    }

    private LunchFundAccount getOrCreateForUpdate(User user) {
        User lockedUser = userRepository.findByIdForUpdate(user.getId())
                .orElseThrow(() -> new IllegalArgumentException("Tài khoản không còn tồn tại"));
        return accountRepository.findByUserForUpdate(lockedUser)
                .orElseGet(() -> accountRepository.saveAndFlush(
                        LunchFundAccount.builder()
                                .user(lockedUser)
                                .balance(0L)
                                .debt(0L)
                                .build()
                ));
    }

    private LunchFundTransaction saveTransaction(
            LunchFundAccount account,
            LunchFundTransactionType type,
            long amount,
            LunchOrder order,
            User actor,
            String note
    ) {
        return transactionRepository.save(
                LunchFundTransaction.builder()
                        .account(account)
                        .type(type)
                        .amount(amount)
                        .balanceAfter(netBalance(account))
                        .order(order)
                        .actor(actor)
                        .note(note)
                        .createdAt(java.time.LocalDateTime.now())
                        .build()
        );
    }
}
