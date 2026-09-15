package com.fittrack.finance.controller;

import com.fittrack.common.dto.PageResponse;
import com.fittrack.finance.dto.FinanceDtos.*;
import com.fittrack.finance.service.FinanceService;
import com.fittrack.user.entity.User;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import java.time.LocalDate;
import java.util.List;

@RestController @RequestMapping("/api/finance") @RequiredArgsConstructor
public class FinanceController {
    private final FinanceService service;
    @GetMapping("/accounts") public List<AccountResponse> accounts(@AuthenticationPrincipal User user){return service.accounts(user);}
    @PostMapping("/accounts") public AccountResponse createAccount(@AuthenticationPrincipal User user,@Valid @RequestBody AccountRequest request){return service.createAccount(user,request);}
    @PutMapping("/accounts/{id}") public AccountResponse updateAccount(@AuthenticationPrincipal User user,@PathVariable String id,@Valid @RequestBody AccountRequest request){return service.updateAccount(user,id,request);}
    @DeleteMapping("/accounts/{id}") public void archiveAccount(@AuthenticationPrincipal User user,@PathVariable String id){service.archiveAccount(user,id);}
    @GetMapping("/categories") public List<CategoryResponse> categories(@AuthenticationPrincipal User user){return service.categories(user);}
    @PostMapping("/categories") public CategoryResponse createCategory(@AuthenticationPrincipal User user,@Valid @RequestBody CategoryRequest request){return service.createCategory(user,request);}
    @PutMapping("/categories/{id}") public CategoryResponse updateCategory(@AuthenticationPrincipal User user,@PathVariable String id,@Valid @RequestBody CategoryRequest request){return service.updateCategory(user,id,request);}
    @DeleteMapping("/categories/{id}") public void archiveCategory(@AuthenticationPrincipal User user,@PathVariable String id){service.archiveCategory(user,id);}
    @GetMapping("/transactions") public PageResponse<TransactionResponse> transactions(@AuthenticationPrincipal User user,@RequestParam(required=false) LocalDate from,@RequestParam(required=false) LocalDate to,@RequestParam(required=false) String accountId,@RequestParam(required=false) String categoryId,@RequestParam(required=false) String type,@RequestParam(required=false) String q,@RequestParam(defaultValue="0") int page,@RequestParam(defaultValue="20") int size){return service.transactions(user,from,to,accountId,categoryId,type,q,page,size);}
    @PostMapping("/transactions") public TransactionResponse createTransaction(@AuthenticationPrincipal User user,@Valid @RequestBody TransactionRequest request){return service.createTransaction(user,request);}
    @PutMapping("/transactions/{id}") public TransactionResponse updateTransaction(@AuthenticationPrincipal User user,@PathVariable String id,@Valid @RequestBody TransactionRequest request){return service.updateTransaction(user,id,request);}
    @DeleteMapping("/transactions/{id}") public void voidTransaction(@AuthenticationPrincipal User user,@PathVariable String id){service.voidTransaction(user,id);}
    @GetMapping("/budgets") public List<BudgetResponse> budgets(@AuthenticationPrincipal User user,@RequestParam(required=false) LocalDate month){return service.budgets(user,month);}
    @PostMapping("/budgets") public BudgetResponse createBudget(@AuthenticationPrincipal User user,@Valid @RequestBody BudgetRequest request){return service.saveBudget(user,null,request);}
    @PutMapping("/budgets/{id}") public BudgetResponse updateBudget(@AuthenticationPrincipal User user,@PathVariable String id,@Valid @RequestBody BudgetRequest request){return service.saveBudget(user,id,request);}
    @DeleteMapping("/budgets/{id}") public void deleteBudget(@AuthenticationPrincipal User user,@PathVariable String id){service.deleteBudget(user,id);}
    @GetMapping("/recurring") public List<RecurringResponse> recurring(@AuthenticationPrincipal User user){return service.recurring(user);}
    @PostMapping("/recurring") public RecurringResponse createRecurring(@AuthenticationPrincipal User user,@Valid @RequestBody RecurringRequest request){return service.createRecurring(user,request);}
    @PutMapping("/recurring/{id}") public RecurringResponse updateRecurring(@AuthenticationPrincipal User user,@PathVariable String id,@Valid @RequestBody RecurringRequest request){return service.updateRecurring(user,id,request);}
    @DeleteMapping("/recurring/{id}") public void archiveRecurring(@AuthenticationPrincipal User user,@PathVariable String id){service.archiveRecurring(user,id);}
    @PostMapping("/recurring/{id}/confirm") public TransactionResponse confirmRecurring(@AuthenticationPrincipal User user,@PathVariable String id){return service.confirmRecurring(user,id);}
    @PostMapping("/recurring/{id}/snooze") public RecurringResponse snoozeRecurring(@AuthenticationPrincipal User user,@PathVariable String id){return service.snoozeRecurring(user,id);}
    @GetMapping("/dashboard") public DashboardResponse dashboard(@AuthenticationPrincipal User user,@RequestParam(required=false) LocalDate month){return service.dashboard(user,month);}
    @GetMapping("/reports/monthly") public MonthlyReportResponse report(@AuthenticationPrincipal User user,@RequestParam(required=false) LocalDate month){return service.report(user,month);}
}
