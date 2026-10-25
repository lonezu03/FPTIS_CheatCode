package com.fittrack.finance.service;

import com.fittrack.common.dto.PageResponse;
import com.fittrack.common.exception.ConflictException;
import com.fittrack.common.exception.ResourceNotFoundException;
import com.fittrack.finance.dto.FinanceDtos.*;
import com.fittrack.finance.entity.FinanceBalanceReconciliation;
import com.fittrack.finance.repository.FinanceAccountRepository;
import com.fittrack.finance.repository.FinanceBalanceReconciliationRepository;
import com.fittrack.user.entity.User;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDateTime;
import java.time.ZoneId;

@Service @RequiredArgsConstructor
public class FinanceReconciliationService {
    private final FinanceAccountRepository accounts;
    private final FinanceBalanceReconciliationRepository history;
    private final FinanceService finance;

    @Transactional
    public ReconciliationResponse reconcile(User user, String id, ReconcileRequest request) {
        // All balance-changing finance operations take these locks in the same order.
        var locked = accounts.lockByOwner(user);
        var account = locked.stream().filter(a -> a.getId().equals(id)).findFirst()
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy tài khoản tài chính"));
        if (!Boolean.TRUE.equals(account.getActive())) throw new IllegalArgumentException("Ví đã lưu trữ; không thể điều chỉnh");
        var current = finance.accounts(user).stream().filter(a -> a.id().equals(id)).findFirst().orElseThrow().currentBalance();
        if (request.expectedBalance() == null || current.compareTo(request.expectedBalance()) != 0) {
            throw new ConflictException("Số dư vừa thay đổi. Hãy tải lại số dư và kiểm tra trước khi xác nhận");
        }
        if (request.note() == null || request.note().isBlank() || request.note().trim().length() > 500) {
            throw new IllegalArgumentException("Cần nhập lý do điều chỉnh, tối đa 500 ký tự");
        }
        BigDecimal actual;
        try { actual = request.actualBalance().setScale(2, RoundingMode.UNNECESSARY); }
        catch (ArithmeticException | NullPointerException ex) { throw new IllegalArgumentException("Số dư thực tế không hợp lệ"); }
        if (actual.precision() > 18) throw new IllegalArgumentException("Số dư thực tế quá lớn");
        var difference = actual.subtract(current);
        if (difference.signum() == 0) throw new IllegalArgumentException("Số dư đã khớp, không cần điều chỉnh");
        var before = account.getOpeningBalance();
        var after = before.add(difference).setScale(2, RoundingMode.UNNECESSARY);
        if (after.precision() > 18) throw new IllegalArgumentException("Số dư điều chỉnh vượt giới hạn của ví");
        account.setOpeningBalance(after);
        accounts.save(account);
        var saved = history.save(FinanceBalanceReconciliation.builder().user(user).account(account)
                .balanceBefore(current).balanceAfter(actual).difference(difference)
                .openingBefore(before).openingAfter(after).note(request.note().trim())
                .createdAt(LocalDateTime.now(ZoneId.of("Asia/Ho_Chi_Minh"))).build());
        return response(saved);
    }

    @Transactional(readOnly = true)
    public PageResponse<ReconciliationResponse> history(User user, String id, int page, int size) {
        accounts.findByIdAndUser(id, user).orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy tài khoản tài chính"));
        var result = history.findByUserAndAccountId(user, id, PageRequest.of(Math.max(0, page), Math.max(1, Math.min(50, size)),
                Sort.by(Sort.Order.desc("createdAt"), Sort.Order.desc("id"))));
        return PageResponse.from(result.map(this::response));
    }

    private ReconciliationResponse response(FinanceBalanceReconciliation row) {
        return new ReconciliationResponse(row.getId(), row.getAccount().getId(), row.getBalanceBefore(),
                row.getBalanceAfter(), row.getDifference(), row.getNote(), row.getCreatedAt());
    }
}
