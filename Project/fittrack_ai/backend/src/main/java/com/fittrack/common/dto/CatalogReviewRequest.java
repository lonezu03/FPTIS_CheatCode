package com.fittrack.common.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public record CatalogReviewRequest(
        @NotBlank(message = "Vui lòng chọn kết quả duyệt")
        @Pattern(
                regexp = "APPROVED|REJECTED",
                message = "Kết quả duyệt chỉ nhận APPROVED hoặc REJECTED"
        )
        String status,
        @Size(max = 500, message = "Ghi chú tối đa 500 ký tự")
        String note
) {
}
