package com.fittrack.quote.dto;

import com.fittrack.quote.entity.QuoteSourceType;
import com.fittrack.quote.entity.QuoteStatus;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

public final class QuoteDtos {
    private QuoteDtos() {
    }

    public record QuoteRequest(
            @NotBlank(message = "Câu nói không được để trống")
            @Size(max = 10_000, message = "Câu nói tối đa 10.000 ký tự")
            String content,
            @Size(max = 255, message = "Tác giả tối đa 255 ký tự")
            String author,
            QuoteSourceType sourceType,
            @Size(max = 500, message = "Tên nguồn tối đa 500 ký tự")
            String sourceTitle,
            @Size(max = 2_000, message = "Đường dẫn nguồn tối đa 2.000 ký tự")
            String sourceUrl,
            @Size(max = 255, message = "Vị trí nguồn tối đa 255 ký tự")
            String sourceLocation,
            @Size(max = 10_000, message = "Ghi chú tối đa 10.000 ký tự")
            String personalNote,
            Boolean includeInDaily,
            @Size(max = 10, message = "Mã ngôn ngữ tối đa 10 ký tự")
            String language,
            @Size(max = 10, message = "Mỗi câu có tối đa 10 nhãn")
            List<String> tags,
            Boolean allowDuplicate
    ) {
    }

    public record DuplicateCheckRequest(
            @NotBlank(message = "Câu nói không được để trống")
            @Size(max = 10_000, message = "Câu nói tối đa 10.000 ký tự")
            String content,
            String excludedId
    ) {
    }

    public record QuoteResponse(
            String id,
            String content,
            String author,
            QuoteSourceType sourceType,
            String sourceTitle,
            String sourceUrl,
            String sourceLocation,
            String personalNote,
            boolean includeInDaily,
            QuoteStatus status,
            String language,
            List<String> tags,
            LocalDateTime createdAt,
            LocalDateTime updatedAt,
            LocalDateTime archivedAt
    ) {
    }

    public record QuoteDetailResponse(
            QuoteResponse quote,
            List<LocalDate> displayedDates
    ) {
    }

    public record DuplicateCheckResponse(
            boolean duplicate,
            QuoteResponse existingQuote
    ) {
    }

    public record DailyQuoteResponse(
            LocalDate displayDate,
            QuoteResponse quote
    ) {
    }

    public record QuoteHistoryResponse(
            String id,
            LocalDate displayDate,
            int cycleNumber,
            QuoteResponse quote
    ) {
    }
}
