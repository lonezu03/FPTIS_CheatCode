package com.fittrack.finance.dto;

import jakarta.validation.constraints.*;
import java.math.BigDecimal;
import java.time.*;
import java.util.List;

public final class FinanceDtos {
    private FinanceDtos() {}

    public record AccountRequest(@NotBlank @Size(max=120) String name,
        @NotBlank @Pattern(regexp="CASH|BANK|EWALLET|SAVINGS|OTHER") String accountType,
        @Pattern(regexp="[A-Z]{3}") String currencyCode, @NotNull BigDecimal openingBalance) {}
    public record AccountResponse(String id,String name,String accountType,String currencyCode,
        BigDecimal openingBalance,BigDecimal currentBalance,boolean active) {}

    public record CategoryRequest(@NotBlank @Size(max=120) String name,
        @NotBlank @Pattern(regexp="EXPENSE|INCOME") String transactionKind,
        @Pattern(regexp="FIXED_MANDATORY|ESSENTIAL_VARIABLE|TRUE_EXPENSE|SAVING|DISCRETIONARY") String expenseNature,
        String parentId,@Size(max=40) String icon) {}
    public record CategoryResponse(String id,String name,String transactionKind,String expenseNature,
        String parentId,String icon,boolean active,boolean systemCategory) {}

    public record TransactionRequest(@NotBlank @Pattern(regexp="EXPENSE|INCOME|TRANSFER") String type,
        @NotNull @DecimalMin(value="0.01") BigDecimal amount,@NotBlank String accountId,
        String destinationAccountId,String categoryId,
        @Pattern(regexp="FIXED_MANDATORY|ESSENTIAL_VARIABLE|TRUE_EXPENSE|SAVING|DISCRETIONARY") String expenseNature,
        @NotNull LocalDateTime occurredAt,
        @Size(max=160) String merchant,@Size(max=1000) String note) {}
    public record TransactionResponse(String id,String type,BigDecimal amount,LocalDateTime occurredAt,
        String accountId,String accountName,String destinationAccountId,String destinationAccountName,
        String categoryId,String categoryName,String expenseNature,String merchant,String note,String status) {}

    public record BudgetRequest(@NotBlank String categoryId,@NotNull LocalDate month,
        @NotNull @DecimalMin(value="0.01") BigDecimal amount,boolean rolloverEnabled) {}
    public record BudgetResponse(String id,String categoryId,String categoryName,LocalDate month,
        BigDecimal amount,BigDecimal spent,BigDecimal remaining,double percent,BigDecimal projected,
        boolean projectedOver,boolean rolloverEnabled) {}

    public record RecurringRequest(@NotBlank @Size(max=160) String name,
        @NotBlank @Pattern(regexp="EXPENSE|INCOME|TRANSFER") String transactionType,
        @NotBlank String accountId,String destinationAccountId,String categoryId,
        @Pattern(regexp="FIXED_MANDATORY|ESSENTIAL_VARIABLE|TRUE_EXPENSE|SAVING|DISCRETIONARY") String expenseNature,
        @NotNull @DecimalMin(value="0.01") BigDecimal amount,
        @NotBlank @Pattern(regexp="WEEKLY|MONTHLY|YEARLY") String frequency,
        @NotNull LocalDate nextDueDate,@Min(0) @Max(30) int remindDaysBefore) {}
    public record RecurringResponse(String id,String name,String transactionType,String accountId,String accountName,
        String destinationAccountId,String categoryId,String categoryName,String expenseNature,BigDecimal amount,
        String frequency,LocalDate nextDueDate,int remindDaysBefore,boolean active) {}

    public record CategoryTotal(String categoryId,String categoryName,String expenseNature,BigDecimal amount) {}
    public record NatureTotal(String expenseNature,BigDecimal amount,double percentOfIncome) {}
    public record DashboardResponse(LocalDate month,BigDecimal totalBalance,BigDecimal income,BigDecimal expense,
        BigDecimal netSaving,double savingRate,BigDecimal mandatoryCommitted,BigDecimal mandatoryPaid,
        BigDecimal mandatoryRemaining,BigDecimal savingCommitted,BigDecimal trueExpensePreparation,BigDecimal flexibleAvailable,
        List<AccountResponse> accounts,List<BudgetResponse> budgets,List<RecurringResponse> upcoming,
        List<CategoryTotal> topCategories,List<NatureTotal> natureBreakdown,String insight) {}
    public record MonthlyReportResponse(LocalDate month,BigDecimal income,BigDecimal expense,BigDecimal netSaving,
        double savingRate,BigDecimal previousExpense,BigDecimal expenseChange,List<CategoryTotal> categories,
        List<NatureTotal> natureBreakdown) {}
}
