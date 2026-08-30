package com.fittrack.nutrition.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDate;
import java.util.List;

@Getter
@Setter
public class UpdateMealLogRequest {
    @NotBlank
    @Pattern(
            regexp = "BREAKFAST|LUNCH|DINNER|SNACK",
            message = "mealType không hợp lệ"
    )
    private String mealType;

    @NotNull
    private LocalDate logDate;

    @NotEmpty
    @Valid
    private List<UpdateMealItemRequest> items;
}

