package com.fittrack.finance.dto;

import jakarta.validation.constraints.NotBlank;
import java.math.BigDecimal;

public final class ReceiptAnalysisDtos {
    private ReceiptAnalysisDtos() {}
    public record Request(@NotBlank String imageData) {}
    public record Response(BigDecimal amount, String occurredAt, String merchant, String note, String warning) {}
}
