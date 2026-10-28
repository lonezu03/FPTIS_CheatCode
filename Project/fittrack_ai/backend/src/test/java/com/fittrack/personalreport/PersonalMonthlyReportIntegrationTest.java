package com.fittrack.personalreport;
import com.fittrack.FittrackBackendApplication;
import com.fittrack.user.entity.User;
import com.fittrack.user.repository.UserRepository;
import com.fittrack.nutrition.entity.*;
import com.fittrack.nutrition.repository.MealLogRepository;
import com.fittrack.nutrition.service.NutritionDayQualityService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.web.server.ResponseStatusException;
import java.time.*;
import java.util.*;
import static org.junit.jupiter.api.Assertions.*;
@SpringBootTest(classes=FittrackBackendApplication.class) @ActiveProfiles("test")
class PersonalMonthlyReportIntegrationTest {
 @Autowired PersonalMonthlyReportService service;
 @Autowired UserRepository users;
 @Autowired MealLogRepository meals;
 @Autowired NutritionDayQualityService quality;
 @Autowired com.fittrack.finance.repository.FinanceAccountRepository accounts;
 @Autowired com.fittrack.finance.repository.FinanceCategoryRepository categories;
 @Autowired com.fittrack.finance.repository.FinanceTransactionRepository transactions;
 @Autowired com.fittrack.finance.service.FinanceService finance;
 private User user(){return users.save(User.builder().email(UUID.randomUUID()+"@example.test").password("encoded").fullName("Report test").role("USER").active(true).fitnessEnabled(true).healthEnabled(true).todoEnabled(true).financeEnabled(true).build());}
 @Test void sectionPermissionIsEnforcedAndUnknownNutritionIsNotZero(){
  var user=user();var month=LocalDate.of(2026,9,1);user.setHealthEnabled(false);users.save(user);assertThrows(ResponseStatusException.class,()->service.report(user,month,Set.of("TRAINING","NUTRITION")));
  var training=service.report(user,month,Set.of("TRAINING"));assertNotNull(training.training());assertNull(training.nutrition());assertNull(training.finance());assertNull(training.habits());
  user.setHealthEnabled(true);users.save(user);var nutrition=service.report(user,month,Set.of("NUTRITION")).nutrition();assertEquals(0,nutrition.qualifyingDays());assertNull(nutrition.averageCalories());assertEquals(0,nutrition.coveragePercent());
 }
 @Test void onlyConfirmedDaysContributeAndOtherOwnersAreExcluded(){
  var user=user();var other=user();var day=LocalDate.of(2026,9,1);
  meals.save(MealLog.builder().user(user).logDate(day).mealType("LUNCH").totalCalories(100.0).totalProtein(10.0).totalCarbs(15.0).totalFat(2.0).build());quality.update(user,day,NutritionDayStatus.COMPLETE,true);
  quality.update(user,day.plusDays(1),NutritionDayStatus.FASTING,false);
  meals.save(MealLog.builder().user(user).logDate(day.plusDays(2)).mealType("LUNCH").totalCalories(900.0).totalProtein(90.0).totalCarbs(90.0).totalFat(10.0).build());
  meals.save(MealLog.builder().user(other).logDate(day).mealType("LUNCH").totalCalories(9000.0).build());quality.update(other,day,NutritionDayStatus.COMPLETE,true);
  var result=service.report(user,day,Set.of("NUTRITION","HABITS","FOCUS","FINANCE"));assertEquals(2,result.nutrition().qualifyingDays());assertEquals(1,result.nutrition().partialDays());assertEquals(50.0,result.nutrition().averageCalories());assertNull(result.training());assertTrue(result.finance().isEmpty());assertTrue(result.focus().isEmpty());
 }
 @Test void emptyInvalidFutureRequestsFail(){var user=user();assertThrows(ResponseStatusException.class,()->service.report(user,LocalDate.of(2026,9,1),Set.of()));assertThrows(ResponseStatusException.class,()->service.report(user,LocalDate.of(2026,9,1),Set.of("JOURNAL")));assertThrows(ResponseStatusException.class,()->service.report(user,LocalDate.now().plusYears(1),Set.of("TRAINING")));}
 @Test void financeKeepsCurrenciesSeparateAndExcludesTransferVoidAndOpeningBalances(){
  var user=user();var day=LocalDate.of(2026,9,1);var amount=new java.math.BigDecimal("1000");
  var account=accounts.save(com.fittrack.finance.entity.FinanceAccount.builder().user(user).name("USD").accountType("CASH").currencyCode("USD").openingBalance(amount).active(true).build());
  var destination=accounts.save(com.fittrack.finance.entity.FinanceAccount.builder().user(user).name("USD khác").accountType("CASH").currencyCode("USD").openingBalance(java.math.BigDecimal.ZERO).active(true).build());
  var vnd=accounts.save(com.fittrack.finance.entity.FinanceAccount.builder().user(user).name("VND").accountType("CASH").currencyCode("VND").openingBalance(amount).active(true).build());
  var category=categories.save(com.fittrack.finance.entity.FinanceCategory.builder().user(user).name("Chi thử").transactionKind("EXPENSE").build());
  for(var spec:List.of(new String[]{"INCOME","100","POSTED"},new String[]{"EXPENSE","40","POSTED"},new String[]{"EXPENSE","50","VOID"}))transactions.save(com.fittrack.finance.entity.FinanceTransaction.builder().user(user).account(account).category(category).type(spec[0]).amount(new java.math.BigDecimal(spec[1])).status(spec[2]).occurredAt(day.atTime(12,0)).build());
  transactions.save(com.fittrack.finance.entity.FinanceTransaction.builder().user(user).account(account).destinationAccount(destination).type("TRANSFER").amount(amount).status("POSTED").occurredAt(day.atTime(12,0)).build());
  transactions.save(com.fittrack.finance.entity.FinanceTransaction.builder().user(user).account(vnd).category(category).type("EXPENSE").amount(amount).status("POSTED").occurredAt(day.atTime(12,0)).build());
  var report=service.report(user,day,Set.of("FINANCE"));assertEquals(2,report.finance().size());var usd=report.finance().stream().filter(c->c.currencyCode().equals("USD")).findFirst().orElseThrow();assertEquals(0,new java.math.BigDecimal(usd.income()).compareTo(new java.math.BigDecimal("100")));assertEquals(0,new java.math.BigDecimal(usd.expense()).compareTo(new java.math.BigDecimal("40")));
  assertThrows(IllegalArgumentException.class,()->finance.updateAccount(user,account.getId(),new com.fittrack.finance.dto.FinanceDtos.AccountRequest("USD","CASH","VND",amount)));
  assertThrows(IllegalArgumentException.class,()->finance.updateAccount(user,destination.getId(),new com.fittrack.finance.dto.FinanceDtos.AccountRequest("USD khác","CASH","VND",java.math.BigDecimal.ZERO)));
 }
}
