package com.fittrack.nutrition.pantry;
import com.fittrack.lunch.service.LunchNotificationService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.support.TransactionTemplate;
import org.springframework.transaction.PlatformTransactionManager;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import java.time.*;
@Component @RequiredArgsConstructor
public class PantryExpiryNotifications {
 private final PantryRepository batches;private final LunchNotificationService notifications;private final PlatformTransactionManager transactions;
 private static final Logger LOG=LoggerFactory.getLogger(PantryExpiryNotifications.class);
 @Scheduled(cron="0 0 8 * * *",zone="Asia/Ho_Chi_Minh") public void remind(){
  LocalDate day=LocalDate.now(ZoneId.of("Asia/Ho_Chi_Minh"));int page=0;
  while(true){var rows=batches.expiring(day,day.plusDays(3),PageRequest.of(page++,100));
   for(var b:rows){try{new TransactionTemplate(transactions).executeWithoutResult(s->{
    if(Boolean.TRUE.equals(b.getUser().getActive())&&("ADMIN".equalsIgnoreCase(b.getUser().getRole())||Boolean.TRUE.equals(b.getUser().getHealthEnabled())))
     notifications.notifyUserOnce(b.getUser(),"PANTRY_EXPIRY","Thực phẩm sắp hết hạn",b.getFood().getName()+" tại "+b.getLocation()+" hết hạn "+b.getExpiresOn()+". Kiểm tra trước khi dùng.","PANTRY",b.getId(),"PANTRY_EXPIRY:"+b.getId()+":"+b.getExpiresOn());
   });}catch(RuntimeException error){LOG.warn("Pantry expiry reminder failed for batch {} ({})",b.getId(),error.getClass().getSimpleName());}}
   if(rows.isLast())break;
  }
 }
}
