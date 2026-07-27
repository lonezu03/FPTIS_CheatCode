package com.fittrack.lunch.service;

import com.fittrack.common.exception.ConflictException;
import com.fittrack.common.exception.ResourceNotFoundException;
import com.fittrack.lunch.dto.LunchDtos.*;
import com.fittrack.lunch.entity.*;
import com.fittrack.lunch.mapper.LunchMapper;
import com.fittrack.lunch.repository.LunchPaymentRequestRepository;
import com.fittrack.lunch.repository.LunchPaymentSettingsRepository;
import com.fittrack.user.entity.User;
import com.fittrack.user.repository.UserRepository;
import com.fittrack.common.media.ImageReferences;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
public class LunchPaymentService {

    private final LunchPaymentSettingsRepository settingsRepository;
    private final LunchPaymentRequestRepository requestRepository;
    private final LunchAccountService accountService;
    private final LunchNotificationService notificationService;
    private final LunchTextFormatter textFormatter;
    private final LunchMapper mapper;
    private final UserRepository userRepository;

    @Transactional(readOnly = true)
    public PaymentSettingsResponse getSettings() {
        return settingsRepository.findById(LunchPaymentSettings.DEFAULT_ID)
                .map(this::toSettingsResponse)
                .orElseGet(() -> new PaymentSettingsResponse(
                        null, null, null, null,
                        "Admin chưa cấu hình mã QR thanh toán",
                        null
                ));
    }

    @Transactional
    public PaymentSettingsResponse updateSettings(UpdatePaymentSettingsRequest request) {
        LunchPaymentSettings settings = settingsRepository
                .findById(LunchPaymentSettings.DEFAULT_ID)
                .orElseGet(() -> LunchPaymentSettings.builder()
                        .id(LunchPaymentSettings.DEFAULT_ID)
                        .build());
        settings.setQrImageUrl(ImageReferences.resolveStoredValue(
                settings.getQrImageUrl(),
                request.qrImageUrl(),
                ImageReferences.paymentQrPath()
        ));
        settings.setBankName(blankToNull(request.bankName()));
        settings.setAccountName(blankToNull(request.accountName()));
        settings.setAccountNumber(blankToNull(request.accountNumber()));
        settings.setInstructions(textFormatter.sanitizeNote(request.instructions()));
        settings.setUpdatedAt(LocalDateTime.now());
        return toSettingsResponse(settingsRepository.save(settings));
    }

    @Transactional
    public PaymentRequestResponse create(User user, CreatePaymentRequest request) {
        user = userRepository.findByIdForUpdate(user.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy tài khoản"));
        PaymentSettingsResponse settings = getSettings();
        if (settings.qrImageUrl() == null || settings.qrImageUrl().isBlank()) {
            throw new ConflictException("Admin chưa cấu hình mã QR thanh toán");
        }
        if (requestRepository.existsByUserAndStatus(user, LunchPaymentRequestStatus.PENDING)) {
            throw new ConflictException("Bạn đang có một yêu cầu thanh toán chờ duyệt");
        }
        if (request.type() == LunchPaymentRequestType.DEBT_PAYMENT) {
            long debt = accountService.outstandingDebt(user);
            if (debt <= 0) {
                throw new ConflictException("Tài khoản hiện không có công nợ");
            }
            if (request.amount() > debt) {
                throw new IllegalArgumentException("Số tiền trả nợ không được lớn hơn công nợ hiện tại");
            }
        }

        LunchPaymentRequest saved = requestRepository.save(LunchPaymentRequest.builder()
                .user(user)
                .type(request.type())
                .amount(request.amount())
                .status(LunchPaymentRequestStatus.PENDING)
                .note(textFormatter.sanitizeNote(request.note()))
                .build());
        notificationService.notifyAdmins(
                "PAYMENT_REQUEST",
                "Có yêu cầu thanh toán mới",
                displayName(user) + " báo đã chuyển " + saved.getAmount() + "đ",
                "PAYMENT_REQUEST",
                saved.getId()
        );
        return mapper.toPaymentRequestResponse(saved);
    }

    @Transactional(readOnly = true)
    public List<PaymentRequestResponse> getMine(User user) {
        return requestRepository.findByUserOrderByCreatedAtDesc(user)
                .stream()
                .map(mapper::toPaymentRequestResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<PaymentRequestResponse> getAll() {
        return requestRepository.findAllByOrderByCreatedAtDesc()
                .stream()
                .map(mapper::toPaymentRequestResponse)
                .toList();
    }

    @Transactional
    public PaymentRequestResponse approve(
            User admin,
            String id,
            ReviewPaymentRequest review
    ) {
        LunchPaymentRequest request = pendingForUpdate(id);
        LunchFundTransactionType transactionType =
                request.getType() == LunchPaymentRequestType.DEBT_PAYMENT
                        ? LunchFundTransactionType.DEBT_PAYMENT
                        : LunchFundTransactionType.FUND_TOP_UP;
        accountService.credit(
                request.getUser(),
                request.getAmount(),
                transactionType,
                null,
                admin,
                "Chuyển khoản được admin phê duyệt"
        );
        request.setStatus(LunchPaymentRequestStatus.APPROVED);
        request.setReviewedBy(admin);
        request.setReviewNote(review == null ? null : textFormatter.sanitizeNote(review.note()));
        request.setReviewedAt(LocalDateTime.now());
        LunchPaymentRequest saved = requestRepository.save(request);
        notificationService.notifyUser(
                request.getUser(),
                "PAYMENT_APPROVED",
                "Thanh toán đã được duyệt",
                "Admin đã xác nhận khoản chuyển " + request.getAmount() + "đ.",
                "PAYMENT_REQUEST",
                request.getId()
        );
        return mapper.toPaymentRequestResponse(saved);
    }

    @Transactional
    public PaymentRequestResponse reject(
            User admin,
            String id,
            ReviewPaymentRequest review
    ) {
        LunchPaymentRequest request = pendingForUpdate(id);
        request.setStatus(LunchPaymentRequestStatus.REJECTED);
        request.setReviewedBy(admin);
        request.setReviewNote(review == null ? null : textFormatter.sanitizeNote(review.note()));
        request.setReviewedAt(LocalDateTime.now());
        LunchPaymentRequest saved = requestRepository.save(request);
        notificationService.notifyUser(
                request.getUser(),
                "PAYMENT_REJECTED",
                "Thanh toán chưa được xác nhận",
                request.getReviewNote() == null
                        ? "Admin chưa nhận được giao dịch. Vui lòng kiểm tra lại."
                        : request.getReviewNote(),
                "PAYMENT_REQUEST",
                request.getId()
        );
        return mapper.toPaymentRequestResponse(saved);
    }

    private LunchPaymentRequest pendingForUpdate(String id) {
        LunchPaymentRequest request = requestRepository.findByIdForUpdate(id)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy yêu cầu thanh toán"));
        if (request.getStatus() != LunchPaymentRequestStatus.PENDING) {
            throw new ConflictException("Yêu cầu này đã được xử lý");
        }
        return request;
    }

    private PaymentSettingsResponse toSettingsResponse(LunchPaymentSettings settings) {
        return new PaymentSettingsResponse(
                ImageReferences.responseUrl(
                        settings.getQrImageUrl(),
                        ImageReferences.paymentQrPath()
                ),
                settings.getBankName(),
                settings.getAccountName(),
                settings.getAccountNumber(),
                settings.getInstructions(),
                settings.getUpdatedAt()
        );
    }

    private String blankToNull(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }

    private String displayName(User user) {
        return user.getFullName() == null || user.getFullName().isBlank()
                ? user.getEmail()
                : user.getFullName();
    }
}
