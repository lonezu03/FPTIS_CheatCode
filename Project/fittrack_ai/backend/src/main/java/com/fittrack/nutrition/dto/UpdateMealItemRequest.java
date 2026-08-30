package com.fittrack.nutrition.dto;

import jakarta.validation.constraints.AssertTrue;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Positive;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class UpdateMealItemRequest {
    @NotBlank
    private String foodId;

    @Positive
    private Double quantity;

    @Positive
    private Double servingAmount;

    @Pattern(regexp = "SERVING|GRAM|ML", message = "servingUnit không hợp lệ")
    private String servingUnit;

    @AssertTrue(message = "Vui lòng nhập số lượng")
    public boolean isAmountPresent() {
        return quantity != null || servingAmount != null;
    }
}

