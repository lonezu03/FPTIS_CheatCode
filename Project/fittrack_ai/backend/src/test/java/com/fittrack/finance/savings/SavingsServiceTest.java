package com.fittrack.finance.savings;
import com.fittrack.user.entity.User;
import com.fittrack.finance.savings.SavingsDtos.*;
import org.junit.jupiter.api.*;
import org.springframework.web.server.ResponseStatusException;
import java.math.BigDecimal;
import java.util.Optional;
import static org.mockito.Mockito.*;
import static org.junit.jupiter.api.Assertions.*;

class SavingsServiceTest {
 final SavingsGoalRepository goals=mock(SavingsGoalRepository.class);
 final SavingsOperationRepository operations=mock(SavingsOperationRepository.class);
 final SavingsService service=new SavingsService(goals,operations);
 final User user=User.builder().id("owner").role("ADMIN").build();
 SavingsGoal goal;
 @BeforeEach void setup(){goal=new SavingsGoal();goal.setId("g");goal.setOwnerId("owner");goal.setCurrencyCode("VND");goal.setProgress(new BigDecimal("100"));goal.setVersion(2L);when(goals.lock("g","owner")).thenReturn(Optional.of(goal));when(operations.save(any())).thenAnswer(i->i.getArgument(0));}
 OperationRequest request(String type,String amount){return new OperationRequest("operation_1",type,new BigDecimal(amount),"VND","manual");}
 @Test void addChangesOnlyVirtualProgress(){service.record(user,"g",request("ADD","20"));assertEquals(new BigDecimal("120"),goal.getProgress());verify(operations).save(any());assertTrue(java.util.Arrays.stream(SavingsService.class.getDeclaredFields()).allMatch(f->java.lang.reflect.Modifier.isStatic(f.getModifiers())||f.getType()==SavingsGoalRepository.class||f.getType()==SavingsOperationRepository.class),"Service must not depend on finance accounts/transactions");}
 @Test void cannotReleaseMoreThanProgress(){assertEquals(409,assertThrows(ResponseStatusException.class,()->service.record(user,"g",request("RELEASE","101"))).getStatusCode().value());assertEquals(new BigDecimal("100"),goal.getProgress());verify(operations,never()).save(any());}
 @Test void retryOperationIsIdempotentAndPayloadMismatchConflict(){var existing=new SavingsOperation();existing.setOperationId("operation_1");existing.setType("ADD");existing.setAmount(new BigDecimal("20"));existing.setNote("manual");when(operations.findByGoalIdAndOperationId("g","operation_1")).thenReturn(Optional.of(existing));service.record(user,"g",request("ADD","20"));assertEquals(new BigDecimal("100"),goal.getProgress());verify(operations,never()).save(any());assertThrows(ResponseStatusException.class,()->service.record(user,"g",request("ADD","21")));}
 @Test void currencyMismatchRejected(){assertEquals(400,assertThrows(ResponseStatusException.class,()->service.record(user,"g",new OperationRequest("operation_1","ADD",BigDecimal.ONE,"USD",null))).getStatusCode().value());}
 @Test void adminCannotReadOtherOwner(){when(goals.findByIdAndOwnerId("other","owner")).thenReturn(Optional.empty());assertEquals(404,assertThrows(ResponseStatusException.class,()->service.history(user,"other",0,15)).getStatusCode().value());}
 @Test void editRequiresVersion(){assertEquals(409,assertThrows(ResponseStatusException.class,()->service.save(user,"g",new Request("Goal",BigDecimal.TEN,"VND",null,null,false,1L))).getStatusCode().value());}
 @Test void amountsAndProgressBoundedToSafeClientPrecision(){assertEquals(400,assertThrows(ResponseStatusException.class,()->service.record(user,"g",request("ADD","1000000000000.01"))).getStatusCode().value());goal.setProgress(new BigDecimal("1000000000000"));assertEquals(400,assertThrows(ResponseStatusException.class,()->service.record(user,"g",request("ADD","0.01"))).getStatusCode().value());assertEquals(400,assertThrows(ResponseStatusException.class,()->service.save(user,null,new Request("Goal",new BigDecimal("1000000000001"),"VND",null,null,false,null))).getStatusCode().value());}
}
