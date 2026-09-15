package com.fittrack.finance.service;

import com.fittrack.common.dto.PageResponse;
import com.fittrack.common.exception.ResourceNotFoundException;
import com.fittrack.finance.dto.FinanceDtos.*;
import com.fittrack.finance.entity.*;
import com.fittrack.finance.repository.*;
import com.fittrack.lunch.service.LunchNotificationService;
import com.fittrack.user.entity.User;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.*;
import java.time.*;
import java.util.*;
import java.util.stream.Collectors;

@Service @RequiredArgsConstructor
public class FinanceService {
    private static final ZoneId ZONE=ZoneId.of("Asia/Ho_Chi_Minh");
    private static final Set<String> ACCOUNT_TYPES=Set.of("CASH","BANK","EWALLET","SAVINGS","OTHER");
    private static final Set<String> TX_TYPES=Set.of("EXPENSE","INCOME","TRANSFER");
    private static final Set<String> NATURES=Set.of("FIXED_MANDATORY","ESSENTIAL_VARIABLE","TRUE_EXPENSE","SAVING","DISCRETIONARY");
    private final FinanceAccountRepository accounts;
    private final FinanceCategoryRepository categories;
    private final FinanceTransactionRepository transactions;
    private final FinanceBudgetRepository budgets;
    private final FinanceRecurringRuleRepository recurring;
    private final LunchNotificationService notifications;

    @Transactional(readOnly=true)
    public List<AccountResponse> accounts(User user){
        var posted=transactions.findByUserAndStatus(user,"POSTED");
        return accounts.findByUserOrderByActiveDescCreatedAtAsc(user).stream().map(a->accountResponse(a,posted)).toList();
    }
    @Transactional public AccountResponse createAccount(User user,AccountRequest r){
        validateAccount(r); var a=FinanceAccount.builder().user(user).name(r.name().trim()).accountType(r.accountType())
            .currencyCode(r.currencyCode()==null?"VND":r.currencyCode()).openingBalance(r.openingBalance()).active(true).build();
        return accountResponse(accounts.save(a),List.of());
    }
    @Transactional public AccountResponse updateAccount(User user,String id,AccountRequest r){
        validateAccount(r); var a=account(user,id); a.setName(r.name().trim());a.setAccountType(r.accountType());
        a.setCurrencyCode(r.currencyCode()==null?"VND":r.currencyCode());a.setOpeningBalance(r.openingBalance());
        return accountResponse(accounts.save(a),transactions.findByUserAndStatus(user,"POSTED"));
    }
    @Transactional public void archiveAccount(User user,String id){var a=account(user,id);a.setActive(false);accounts.save(a);}

    @Transactional public List<CategoryResponse> categories(User user){ensureDefaultCategories(user);return categories.findByUserOrderByTransactionKindAscNameAsc(user).stream().map(this::categoryResponse).toList();}
    @Transactional public CategoryResponse createCategory(User user,CategoryRequest r){
        validateCategory(r); FinanceCategory parent=r.parentId()==null?null:category(user,r.parentId());
        var value=FinanceCategory.builder().user(user).name(r.name().trim()).transactionKind(r.transactionKind())
            .expenseNature("INCOME".equals(r.transactionKind())?null:r.expenseNature()).parent(parent).icon(trim(r.icon())).active(true).systemCategory(false).build();
        return categoryResponse(categories.save(value));
    }
    @Transactional public CategoryResponse updateCategory(User user,String id,CategoryRequest r){
        validateCategory(r);var value=category(user,id);value.setName(r.name().trim());value.setTransactionKind(r.transactionKind());
        value.setExpenseNature("INCOME".equals(r.transactionKind())?null:r.expenseNature());value.setIcon(trim(r.icon()));
        value.setParent(r.parentId()==null?null:category(user,r.parentId()));return categoryResponse(categories.save(value));
    }
    @Transactional public void archiveCategory(User user,String id){var c=category(user,id);c.setActive(false);categories.save(c);}

    @Transactional(readOnly=true)
    public PageResponse<TransactionResponse> transactions(User user,LocalDate from,LocalDate to,String accountId,String categoryId,String type,String q,int page,int size){
        int safeSize=Math.max(1,Math.min(size,100)); var result=transactions.search(user,from==null?null:from.atStartOfDay(),
            to==null?null:to.plusDays(1).atStartOfDay(),blank(accountId),blank(categoryId),upper(type),blank(q),PageRequest.of(Math.max(0,page),safeSize));
        return PageResponse.from(result.map(this::transactionResponse));
    }
    @Transactional public TransactionResponse createTransaction(User user,TransactionRequest r){var tx=new FinanceTransaction();tx.setUser(user);applyTransaction(user,tx,r);var saved=transactions.save(tx);checkBudgetAlerts(user,saved.getOccurredAt().toLocalDate());return transactionResponse(saved);}
    @Transactional public TransactionResponse updateTransaction(User user,String id,TransactionRequest r){var tx=transaction(user,id);if(tx.getSourceType()!=null)throw new IllegalArgumentException("Giao dịch đồng bộ không thể sửa thủ công");applyTransaction(user,tx,r);var saved=transactions.save(tx);checkBudgetAlerts(user,saved.getOccurredAt().toLocalDate());return transactionResponse(saved);}
    @Transactional public void voidTransaction(User user,String id){var tx=transaction(user,id);if(tx.getSourceType()!=null)throw new IllegalArgumentException("Giao dịch đồng bộ không thể xóa thủ công");tx.setStatus("VOID");tx.setDeletedAt(LocalDateTime.now(ZONE));transactions.save(tx);}

    @Transactional(readOnly=true) public List<BudgetResponse> budgets(User user,LocalDate month){LocalDate start=monthStart(month);return budgetResponses(user,start);}
    @Transactional public BudgetResponse saveBudget(User user,String id,BudgetRequest r){
        LocalDate month=monthStart(r.month());var c=category(user,r.categoryId());if(!"EXPENSE".equals(c.getTransactionKind()))throw new IllegalArgumentException("Ngân sách chỉ áp dụng cho danh mục chi tiêu");
        FinanceBudget b=id==null?budgets.findByUserAndCategoryIdAndMonthStart(user,c.getId(),month).orElseGet(()->FinanceBudget.builder().user(user).build()):budget(user,id);
        b.setCategory(c);b.setMonthStart(month);b.setAmount(r.amount());b.setRolloverEnabled(r.rolloverEnabled());b.setWarned80At(null);b.setWarned100At(null);budgets.save(b);
        return budgetResponses(user,month).stream().filter(x->Objects.equals(x.id(),b.getId())).findFirst().orElseThrow();
    }
    @Transactional public void deleteBudget(User user,String id){budgets.delete(budget(user,id));}

    @Transactional(readOnly=true) public List<RecurringResponse> recurring(User user){return recurring.findByUserOrderByActiveDescNextDueDateAsc(user).stream().map(this::recurringResponse).toList();}
    @Transactional public RecurringResponse createRecurring(User user,RecurringRequest r){var rule=new FinanceRecurringRule();rule.setUser(user);applyRecurring(user,rule,r);rule.setActive(true);return recurringResponse(recurring.save(rule));}
    @Transactional public RecurringResponse updateRecurring(User user,String id,RecurringRequest r){var rule=rule(user,id);applyRecurring(user,rule,r);return recurringResponse(recurring.save(rule));}
    @Transactional public void archiveRecurring(User user,String id){var rule=rule(user,id);rule.setActive(false);recurring.save(rule);}
    @Transactional public TransactionResponse confirmRecurring(User user,String id){var rule=rule(user,id);if(!Boolean.TRUE.equals(rule.getActive()))throw new IllegalArgumentException("Khoản định kỳ đã ngừng hoạt động");
        TransactionRequest request=new TransactionRequest(rule.getTransactionType(),rule.getAmount(),rule.getAccount().getId(),
            rule.getDestinationAccount()==null?null:rule.getDestinationAccount().getId(),rule.getCategory()==null?null:rule.getCategory().getId(),
            rule.getExpenseNature(),rule.getNextDueDate().atTime(12,0),rule.getName(),"Xác nhận khoản định kỳ");
        var response=createTransaction(user,request);rule.setNextDueDate(next(rule.getNextDueDate(),rule.getFrequency()));rule.setLastNotifiedFor(null);recurring.save(rule);return response;}

    @Transactional(readOnly=true) public DashboardResponse dashboard(User user,LocalDate requestedMonth){
        LocalDate month=monthStart(requestedMonth);var values=transactions.findByUserAndOccurredAtBetweenAndStatus(user,month.atStartOfDay(),month.plusMonths(1).atStartOfDay(),"POSTED");
        BigDecimal income=sum(values,"INCOME"),expense=sum(values,"EXPENSE"),net=income.subtract(expense);var accountList=accounts(user);BigDecimal balance=accountList.stream().map(AccountResponse::currentBalance).reduce(BigDecimal.ZERO,BigDecimal::add);
        var budgetList=budgetResponses(user,month);var upcoming=recurring.findByUserOrderByActiveDescNextDueDateAsc(user).stream().filter(x->Boolean.TRUE.equals(x.getActive())&&!x.getNextDueDate().isBefore(LocalDate.now(ZONE))).limit(8).map(this::recurringResponse).toList();
        var top=categoryTotals(values);var nature=natureTotals(values,income);var monthRules=recurring.findByUserOrderByActiveDescNextDueDateAsc(user).stream().filter(x->Boolean.TRUE.equals(x.getActive())&&"EXPENSE".equals(x.getTransactionType())&&!x.getNextDueDate().isBefore(month)&&x.getNextDueDate().isBefore(month.plusMonths(1))).toList();
        BigDecimal mandatoryPaid=values.stream().filter(x->"EXPENSE".equals(x.getType())&&isMandatory(x.getExpenseNature())).map(FinanceTransaction::getAmount).reduce(BigDecimal.ZERO,BigDecimal::add);
        BigDecimal mandatoryFuture=monthRules.stream().filter(x->isMandatory(nature(x))).map(FinanceRecurringRule::getAmount).reduce(BigDecimal.ZERO,BigDecimal::add);
        BigDecimal mandatory=mandatoryPaid.add(mandatoryFuture);
        BigDecimal savingPaid=values.stream().filter(x->"EXPENSE".equals(x.getType())&&"SAVING".equals(x.getExpenseNature())).map(FinanceTransaction::getAmount).reduce(BigDecimal.ZERO,BigDecimal::add);
        BigDecimal savingFuture=monthRules.stream().filter(x->"SAVING".equals(nature(x))).map(FinanceRecurringRule::getAmount).reduce(BigDecimal.ZERO,BigDecimal::add);
        BigDecimal saving=savingPaid.add(savingFuture);
        BigDecimal trueExpensePreparation=recurring.findByUserOrderByActiveDescNextDueDateAsc(user).stream().filter(x->Boolean.TRUE.equals(x.getActive())&&"EXPENSE".equals(x.getTransactionType())&&"TRUE_EXPENSE".equals(nature(x))).map(this::monthlyPreparation).reduce(BigDecimal.ZERO,BigDecimal::add);
        BigDecimal remaining=mandatoryFuture;BigDecimal flexible=income.subtract(mandatory).subtract(saving).subtract(trueExpensePreparation).max(BigDecimal.ZERO);
        double rate=income.signum()==0?0:pct(net,income);String insight=income.signum()==0?"Hãy ghi thu nhập để FitTrack tính tiền có thể sử dụng.":String.format(Locale.forLanguageTag("vi-VN"),"%.1f%% thu nhập đã cam kết cho chi phí bắt buộc. Bạn còn khoảng %,.0f đ để sử dụng linh hoạt.",pct(mandatory,income),flexible);
        return new DashboardResponse(month,balance,income,expense,net,rate,mandatory,mandatoryPaid,remaining,saving,trueExpensePreparation,flexible,accountList,budgetList,upcoming,top,nature,insight);
    }
    @Transactional(readOnly=true) public MonthlyReportResponse report(User user,LocalDate requestedMonth){LocalDate month=monthStart(requestedMonth);var current=transactions.findByUserAndOccurredAtBetweenAndStatus(user,month.atStartOfDay(),month.plusMonths(1).atStartOfDay(),"POSTED");var previous=transactions.findByUserAndOccurredAtBetweenAndStatus(user,month.minusMonths(1).atStartOfDay(),month.atStartOfDay(),"POSTED");BigDecimal income=sum(current,"INCOME"),expense=sum(current,"EXPENSE"),prev=sum(previous,"EXPENSE"),net=income.subtract(expense);return new MonthlyReportResponse(month,income,expense,net,income.signum()==0?0:pct(net,income),prev,expense.subtract(prev),categoryTotals(current),natureTotals(current,income));}

    @Scheduled(cron="0 0 7 * * *",zone="Asia/Ho_Chi_Minh") @Transactional public void notifyDueRecurring(){LocalDate today=LocalDate.now(ZONE);for(var r:recurring.findByActiveTrueAndNextDueDateLessThanEqual(today.plusDays(30))){var owner=r.getUser();if(!Boolean.TRUE.equals(owner.getActive())||(!"ADMIN".equals(owner.getRole())&&!Boolean.TRUE.equals(owner.getFinanceEnabled())))continue;if(r.getLastNotifiedFor()!=null&&r.getLastNotifiedFor().equals(r.getNextDueDate()))continue;if(today.isBefore(r.getNextDueDate().minusDays(r.getRemindDaysBefore())))continue;notifications.notifyUserOnce(owner,"FINANCE_BILL_DUE","Khoản tài chính sắp đến hạn",r.getName()+" · "+r.getAmount().toPlainString()+" đ · hạn "+r.getNextDueDate(),"FINANCE_RECURRING",r.getId(),"finance-recurring:"+r.getId()+":"+r.getNextDueDate());r.setLastNotifiedFor(r.getNextDueDate());}}

    private void checkBudgetAlerts(User user,LocalDate date){LocalDate month=monthStart(date);for(var b:budgets.findByUserAndMonthStartOrderByCategoryNameAsc(user,month)){BigDecimal spent=spent(user,b.getCategory().getId(),month);double percent=pct(spent,b.getAmount());if(percent>=100&&b.getWarned100At()==null){notifications.notifyUserOnce(user,"FINANCE_BUDGET","Đã dùng hết ngân sách",b.getCategory().getName()+": "+spent.toPlainString()+" / "+b.getAmount().toPlainString()+" đ","FINANCE_BUDGET",b.getId(),"finance-budget:100:"+b.getId());b.setWarned100At(LocalDateTime.now(ZONE));}else if(percent>=80&&b.getWarned80At()==null){notifications.notifyUserOnce(user,"FINANCE_BUDGET","Ngân sách đã đạt 80%",b.getCategory().getName()+" còn "+b.getAmount().subtract(spent).max(BigDecimal.ZERO).toPlainString()+" đ","FINANCE_BUDGET",b.getId(),"finance-budget:80:"+b.getId());b.setWarned80At(LocalDateTime.now(ZONE));}}}
    private List<BudgetResponse> budgetResponses(User user,LocalDate month){int days=month.lengthOfMonth();int elapsed=month.equals(monthStart(LocalDate.now(ZONE)))?LocalDate.now(ZONE).getDayOfMonth():days;return budgets.findByUserAndMonthStartOrderByCategoryNameAsc(user,month).stream().map(b->{BigDecimal s=spent(user,b.getCategory().getId(),month);BigDecimal projected=s.multiply(BigDecimal.valueOf(days)).divide(BigDecimal.valueOf(Math.max(1,elapsed)),2,RoundingMode.HALF_UP);return new BudgetResponse(b.getId(),b.getCategory().getId(),b.getCategory().getName(),month,b.getAmount(),s,b.getAmount().subtract(s),pct(s,b.getAmount()),projected,projected.compareTo(b.getAmount())>0,Boolean.TRUE.equals(b.getRolloverEnabled()));}).toList();}
    private BigDecimal spent(User user,String categoryId,LocalDate month){return transactions.findByUserAndOccurredAtBetweenAndStatus(user,month.atStartOfDay(),month.plusMonths(1).atStartOfDay(),"POSTED").stream().filter(x->"EXPENSE".equals(x.getType())&&x.getCategory()!=null&&categoryId.equals(x.getCategory().getId())).map(FinanceTransaction::getAmount).reduce(BigDecimal.ZERO,BigDecimal::add);}
    private List<CategoryTotal> categoryTotals(List<FinanceTransaction> values){return values.stream().filter(x->"EXPENSE".equals(x.getType())&&x.getCategory()!=null).collect(Collectors.groupingBy(FinanceTransaction::getCategory,Collectors.reducing(BigDecimal.ZERO,FinanceTransaction::getAmount,BigDecimal::add))).entrySet().stream().sorted(Map.Entry.<FinanceCategory,BigDecimal>comparingByValue().reversed()).limit(8).map(e->new CategoryTotal(e.getKey().getId(),e.getKey().getName(),e.getKey().getExpenseNature(),e.getValue())).toList();}
    private List<NatureTotal> natureTotals(List<FinanceTransaction> values,BigDecimal income){return values.stream().filter(x->"EXPENSE".equals(x.getType())).collect(Collectors.groupingBy(x->Optional.ofNullable(x.getExpenseNature()).orElse("UNCLASSIFIED"),Collectors.reducing(BigDecimal.ZERO,FinanceTransaction::getAmount,BigDecimal::add))).entrySet().stream().map(e->new NatureTotal(e.getKey(),e.getValue(),income.signum()==0?0:pct(e.getValue(),income))).sorted(Comparator.comparing(NatureTotal::amount).reversed()).toList();}
    private BigDecimal sum(List<FinanceTransaction> values,String type){return values.stream().filter(x->type.equals(x.getType())).map(FinanceTransaction::getAmount).reduce(BigDecimal.ZERO,BigDecimal::add);}
    private double pct(BigDecimal a,BigDecimal b){return b.signum()==0?0:a.multiply(BigDecimal.valueOf(100)).divide(b,2,RoundingMode.HALF_UP).doubleValue();}
    private void applyTransaction(User user,FinanceTransaction tx,TransactionRequest r){String type=upper(r.type());if(!TX_TYPES.contains(type))throw new IllegalArgumentException("Loại giao dịch không hợp lệ");var from=account(user,r.accountId());if(!Boolean.TRUE.equals(from.getActive()))throw new IllegalArgumentException("Tài khoản nguồn đã lưu trữ");tx.setType(type);tx.setAmount(r.amount());tx.setAccount(from);tx.setOccurredAt(r.occurredAt());tx.setMerchant(trim(r.merchant()));tx.setNote(trim(r.note()));tx.setStatus("POSTED");tx.setDeletedAt(null);if("TRANSFER".equals(type)){var to=account(user,r.destinationAccountId());if(from.getId().equals(to.getId()))throw new IllegalArgumentException("Tài khoản nhận phải khác tài khoản nguồn");if(!Boolean.TRUE.equals(to.getActive()))throw new IllegalArgumentException("Tài khoản nhận đã lưu trữ");if(!from.getCurrencyCode().equals(to.getCurrencyCode()))throw new IllegalArgumentException("Chuyển khoản khác loại tiền chưa được hỗ trợ");tx.setDestinationAccount(to);tx.setCategory(null);tx.setExpenseNature(null);}else{var c=category(user,r.categoryId());if(!Boolean.TRUE.equals(c.getActive()))throw new IllegalArgumentException("Danh mục đã lưu trữ");if(!type.equals(c.getTransactionKind()))throw new IllegalArgumentException("Danh mục không khớp loại giao dịch");tx.setCategory(c);tx.setDestinationAccount(null);String nature="EXPENSE".equals(type)?Optional.ofNullable(r.expenseNature()).orElse(c.getExpenseNature()):null;if(nature!=null&&!NATURES.contains(nature))throw new IllegalArgumentException("Tính chất khoản chi không hợp lệ");tx.setExpenseNature(nature);}}
    private void applyRecurring(User user,FinanceRecurringRule x,RecurringRequest r){String type=upper(r.transactionType()),frequency=upper(r.frequency());if(!TX_TYPES.contains(type))throw new IllegalArgumentException("Loại giao dịch định kỳ không hợp lệ");if(!Set.of("WEEKLY","MONTHLY","YEARLY").contains(frequency))throw new IllegalArgumentException("Chu kỳ không hợp lệ");var from=account(user,r.accountId());if(!Boolean.TRUE.equals(from.getActive()))throw new IllegalArgumentException("Tài khoản đã lưu trữ");x.setName(r.name().trim());x.setTransactionType(type);x.setAccount(from);x.setAmount(r.amount());x.setFrequency(frequency);x.setNextDueDate(r.nextDueDate());x.setRemindDaysBefore(r.remindDaysBefore());if("TRANSFER".equals(type)){var to=account(user,r.destinationAccountId());if(from.getId().equals(to.getId()))throw new IllegalArgumentException("Tài khoản nhận phải khác tài khoản nguồn");if(!Boolean.TRUE.equals(to.getActive())||!from.getCurrencyCode().equals(to.getCurrencyCode()))throw new IllegalArgumentException("Tài khoản nhận không hợp lệ");x.setDestinationAccount(to);x.setCategory(null);x.setExpenseNature(null);}else{var c=category(user,r.categoryId());if(!Boolean.TRUE.equals(c.getActive())||!type.equals(c.getTransactionKind()))throw new IllegalArgumentException("Danh mục không khớp loại giao dịch");x.setDestinationAccount(null);x.setCategory(c);String nature="EXPENSE".equals(type)?Optional.ofNullable(r.expenseNature()).orElse(c.getExpenseNature()):null;if(nature!=null&&!NATURES.contains(nature))throw new IllegalArgumentException("Tính chất khoản chi không hợp lệ");x.setExpenseNature(nature);}x.setLastNotifiedFor(null);}
    private void ensureDefaultCategories(User user){if(categories.existsByUser(user))return;record Seed(String name,String kind,String nature,String icon){}var seeds=List.of(new Seed("Ăn uống","EXPENSE","ESSENTIAL_VARIABLE","utensils"),new Seed("Nhà ở","EXPENSE","FIXED_MANDATORY","house"),new Seed("Điện nước","EXPENSE","ESSENTIAL_VARIABLE","zap"),new Seed("Di chuyển","EXPENSE","ESSENTIAL_VARIABLE","car"),new Seed("Sức khỏe","EXPENSE","ESSENTIAL_VARIABLE","heart"),new Seed("Gia đình","EXPENSE","FIXED_MANDATORY","users"),new Seed("Nợ & nghĩa vụ","EXPENSE","FIXED_MANDATORY","landmark"),new Seed("Chuẩn bị tương lai","EXPENSE","TRUE_EXPENSE","calendar"),new Seed("Tiết kiệm","EXPENSE","SAVING","piggy-bank"),new Seed("Giải trí & tùy ý","EXPENSE","DISCRETIONARY","gamepad"),new Seed("Lương","INCOME",null,"wallet"),new Seed("Thưởng","INCOME",null,"gift"),new Seed("Freelance","INCOME",null,"briefcase"),new Seed("Thu nhập khác","INCOME",null,"plus"));for(var s:seeds)categories.save(FinanceCategory.builder().user(user).name(s.name()).transactionKind(s.kind()).expenseNature(s.nature()).icon(s.icon()).active(true).systemCategory(true).build());}
    private AccountResponse accountResponse(FinanceAccount a,List<FinanceTransaction> txs){BigDecimal balance=a.getOpeningBalance();for(var t:txs){if("VOID".equals(t.getStatus()))continue;if(t.getAccount().getId().equals(a.getId()))balance=switch(t.getType()){case "INCOME"->balance.add(t.getAmount());case "EXPENSE","TRANSFER"->balance.subtract(t.getAmount());default->balance;};if("TRANSFER".equals(t.getType())&&t.getDestinationAccount()!=null&&t.getDestinationAccount().getId().equals(a.getId()))balance=balance.add(t.getAmount());}return new AccountResponse(a.getId(),a.getName(),a.getAccountType(),a.getCurrencyCode(),a.getOpeningBalance(),balance,Boolean.TRUE.equals(a.getActive()));}
    private CategoryResponse categoryResponse(FinanceCategory c){return new CategoryResponse(c.getId(),c.getName(),c.getTransactionKind(),c.getExpenseNature(),c.getParent()==null?null:c.getParent().getId(),c.getIcon(),Boolean.TRUE.equals(c.getActive()),Boolean.TRUE.equals(c.getSystemCategory()));}
    private TransactionResponse transactionResponse(FinanceTransaction t){return new TransactionResponse(t.getId(),t.getType(),t.getAmount(),t.getOccurredAt(),t.getAccount().getId(),t.getAccount().getName(),t.getDestinationAccount()==null?null:t.getDestinationAccount().getId(),t.getDestinationAccount()==null?null:t.getDestinationAccount().getName(),t.getCategory()==null?null:t.getCategory().getId(),t.getCategory()==null?null:t.getCategory().getName(),t.getExpenseNature(),t.getMerchant(),t.getNote(),t.getStatus());}
    private RecurringResponse recurringResponse(FinanceRecurringRule r){return new RecurringResponse(r.getId(),r.getName(),r.getTransactionType(),r.getAccount().getId(),r.getAccount().getName(),r.getDestinationAccount()==null?null:r.getDestinationAccount().getId(),r.getCategory()==null?null:r.getCategory().getId(),r.getCategory()==null?null:r.getCategory().getName(),r.getExpenseNature()!=null?r.getExpenseNature():r.getCategory()==null?null:r.getCategory().getExpenseNature(),r.getAmount(),r.getFrequency(),r.getNextDueDate(),r.getRemindDaysBefore(),Boolean.TRUE.equals(r.getActive()));}
    private FinanceAccount account(User u,String id){if(id==null)throw new IllegalArgumentException("Thiếu tài khoản");return accounts.findByIdAndUser(id,u).orElseThrow(()->new ResourceNotFoundException("Không tìm thấy tài khoản tài chính"));}
    private FinanceCategory category(User u,String id){if(id==null)throw new IllegalArgumentException("Thiếu danh mục");return categories.findByIdAndUser(id,u).orElseThrow(()->new ResourceNotFoundException("Không tìm thấy danh mục tài chính"));}
    private FinanceTransaction transaction(User u,String id){return transactions.findByIdAndUser(id,u).orElseThrow(()->new ResourceNotFoundException("Không tìm thấy giao dịch"));}
    private FinanceBudget budget(User u,String id){return budgets.findByIdAndUser(id,u).orElseThrow(()->new ResourceNotFoundException("Không tìm thấy ngân sách"));}
    private FinanceRecurringRule rule(User u,String id){return recurring.findByIdAndUser(id,u).orElseThrow(()->new ResourceNotFoundException("Không tìm thấy khoản định kỳ"));}
    private void validateAccount(AccountRequest r){if(!ACCOUNT_TYPES.contains(r.accountType()))throw new IllegalArgumentException("Loại tài khoản không hợp lệ");}
    private void validateCategory(CategoryRequest r){if(!Set.of("EXPENSE","INCOME").contains(r.transactionKind()))throw new IllegalArgumentException("Loại danh mục không hợp lệ");if("EXPENSE".equals(r.transactionKind())&&(r.expenseNature()==null||!NATURES.contains(r.expenseNature())))throw new IllegalArgumentException("Tính chất khoản chi không hợp lệ");}
    private boolean isMandatory(String value){return "FIXED_MANDATORY".equals(value)||"ESSENTIAL_VARIABLE".equals(value);}
    private String nature(FinanceRecurringRule value){return value.getExpenseNature()!=null?value.getExpenseNature():value.getCategory()==null?null:value.getCategory().getExpenseNature();}
    private BigDecimal monthlyPreparation(FinanceRecurringRule value){return switch(value.getFrequency()){case "WEEKLY"->value.getAmount().multiply(BigDecimal.valueOf(52)).divide(BigDecimal.valueOf(12),2,RoundingMode.HALF_UP);case "YEARLY"->value.getAmount().divide(BigDecimal.valueOf(12),2,RoundingMode.HALF_UP);default->value.getAmount();};}
    private LocalDate monthStart(LocalDate value){return (value==null?LocalDate.now(ZONE):value).withDayOfMonth(1);}
    private LocalDate next(LocalDate date,String frequency){return switch(frequency){case "WEEKLY"->date.plusWeeks(1);case "YEARLY"->date.plusYears(1);default->date.plusMonths(1);};}
    private String trim(String v){return v==null||v.isBlank()?null:v.trim();} private String blank(String v){return trim(v);} private String upper(String v){return v==null||v.isBlank()?null:v.trim().toUpperCase();}
}
