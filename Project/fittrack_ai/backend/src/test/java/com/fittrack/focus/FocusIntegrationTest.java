package com.fittrack.focus;
import com.fittrack.FittrackBackendApplication;
import com.fittrack.user.entity.User;
import com.fittrack.user.repository.UserRepository;
import com.fittrack.todo.entity.Todo;
import com.fittrack.todo.repository.TodoRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.web.server.ResponseStatusException;
import java.time.*;
import java.util.*;
import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest(classes=FittrackBackendApplication.class) @ActiveProfiles("test")
class FocusIntegrationTest {
 @Autowired FocusService service;
 @Autowired FocusRepository sessions;
 @Autowired UserRepository users;
 @Autowired TodoRepository todos;
 private User user(String role){return users.save(User.builder().email(UUID.randomUUID()+"@example.test").password("encoded").fullName("Focus test").role(role).active(true).todoEnabled(true).build());}
 private String op(){return UUID.randomUUID().toString();}
 @Test void pauseResumeFinishAreVersionedAndRetriesNeverDoubleCount(){
  var user=user("USER");var start=new FocusDtos.Start(op(),null,"Viết báo cáo","FOCUS",25);var first=service.start(user,start);assertEquals(first,service.start(user,start));
  assertThrows(ResponseStatusException.class,()->service.start(user,new FocusDtos.Start(op(),null,"Khác","FOCUS",25)));
  var e=sessions.findById(first.id()).orElseThrow();e.setRunningSince(LocalDateTime.now(ZoneId.of("Asia/Ho_Chi_Minh")).minusMinutes(2));sessions.saveAndFlush(e);var current=service.detail(user,e.getId());
  var pause=new FocusDtos.Command(op(),current.version(),"PAUSE");var paused=service.command(user,e.getId(),pause);assertEquals("PAUSED",paused.state());assertTrue(paused.elapsedSeconds()>=119);assertEquals(paused,service.command(user,e.getId(),pause));
  assertThrows(ResponseStatusException.class,()->service.command(user,e.getId(),new FocusDtos.Command(op(),current.version(),"FINISH")));
  var resumed=service.command(user,e.getId(),new FocusDtos.Command(op(),paused.version(),"RESUME"));var finish=new FocusDtos.Command(op(),resumed.version(),"FINISH");var ended=service.command(user,e.getId(),finish);assertEquals("COMPLETED",ended.state());assertEquals(ended,service.command(user,e.getId(),finish));assertNull(service.active(user));
  assertEquals(1,service.history(user,LocalDate.now().minusDays(1),LocalDate.now().plusDays(1),0,15).totalElements());
 }
 @Test void ownerAdminAndTodoAreIsolatedAndFocusDoesNotCompleteTask(){
  var owner=user("USER");var admin=user("ADMIN");var todo=todos.saveAndFlush(Todo.builder().user(owner).title("Công việc").build());
  assertThrows(ResponseStatusException.class,()->service.start(admin,new FocusDtos.Start(op(),todo.getId(),null,"FOCUS",10)));
  var first=service.start(owner,new FocusDtos.Start(op(),todo.getId(),null,"FOCUS",10));assertThrows(ResponseStatusException.class,()->service.detail(admin,first.id()));assertNull(service.active(admin));
  todos.deleteById(todo.getId());var result=service.command(owner,first.id(),new FocusDtos.Command(op(),first.version(),"FINISH"));assertEquals("Công việc",result.title());assertFalse(todos.existsById(todo.getId()));
  var todo2=todos.saveAndFlush(Todo.builder().user(owner).title("Giữ trạng thái").build());var second=service.start(owner,new FocusDtos.Start(op(),todo2.getId(),null,"BREAK",5));service.command(owner,second.id(),new FocusDtos.Command(op(),second.version(),"FINISH"));assertEquals(Todo.TodoStatus.OPEN,todos.findById(todo2.getId()).orElseThrow().getStatus());
 }
 @Test void overlongRequiresReviewAndCancelledSessionsRemainAuditable(){
  var user=user("USER");var s=service.start(user,new FocusDtos.Start(op(),null,"Dài","FOCUS",25));var e=sessions.findById(s.id()).orElseThrow();var nineHoursAgo=LocalDateTime.now(ZoneId.of("Asia/Ho_Chi_Minh")).minusHours(9);e.setCreatedAt(nineHoursAgo);e.setRunningSince(nineHoursAgo);sessions.saveAndFlush(e);var current=service.detail(user,e.getId());assertTrue(current.reviewRequired());assertEquals(28800,current.elapsedSeconds());
  assertThrows(ResponseStatusException.class,()->service.command(user,e.getId(),new FocusDtos.Command(op(),current.version(),"PAUSE")));
  var ended=service.command(user,e.getId(),new FocusDtos.Command(op(),current.version(),"CANCEL"));assertEquals("CANCELLED",ended.state());assertTrue(ended.reviewRequired());assertEquals(28800,ended.elapsedSeconds());
 }
 @Test void concurrentStartsWithSameOperationReturnOneSession() throws Exception {
  var u=user("USER");var request=new FocusDtos.Start(op(),null,"Một phiên","FOCUS",25);var gate=new java.util.concurrent.CountDownLatch(1);
  try(var pool=java.util.concurrent.Executors.newFixedThreadPool(2)){
   var a=pool.submit(()->{gate.await();return service.start(u,request);});var b=pool.submit(()->{gate.await();return service.start(u,request);});gate.countDown();assertEquals(a.get(20,java.util.concurrent.TimeUnit.SECONDS),b.get(20,java.util.concurrent.TimeUnit.SECONDS));
  }
  assertEquals(1,service.history(u,LocalDate.now().minusDays(1),LocalDate.now().plusDays(1),0,15).totalElements());
 }
}
