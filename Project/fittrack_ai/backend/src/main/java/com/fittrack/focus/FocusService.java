package com.fittrack.focus;

import static com.fittrack.focus.FocusDtos.*;
import com.fittrack.common.dto.PageResponse;
import com.fittrack.user.entity.User;
import com.fittrack.user.repository.UserRepository;
import com.fittrack.todo.entity.Todo;
import com.fittrack.todo.repository.TodoRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;
import tools.jackson.databind.ObjectMapper;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.*;
import java.util.*;

@Service @RequiredArgsConstructor
public class FocusService {
 private final FocusRepository sessions;
 private final FocusOperationRepository operations;
 private final UserRepository users;
 private final TodoRepository todos;
 private final ObjectMapper json;
 private static final Set<String> ACTIVE=Set.of("RUNNING","PAUSED");
 private static final int MAX_SECONDS=8*3600;
 private LocalDateTime now(){return LocalDateTime.now(ZoneId.of("Asia/Ho_Chi_Minh"));}
 private void permission(User user){if(!Boolean.TRUE.equals(user.getActive())||(!"ADMIN".equals(user.getRole())&&!Boolean.TRUE.equals(user.getTodoEnabled())))throw error(403,"Chưa được cấp quyền việc cần làm");}
 @Transactional(readOnly=true) public View active(User user){permission(user);return sessions.findFirstByOwnerIdAndStateInOrderByCreatedAtDesc(user.getId(),ACTIVE).map(this::view).orElse(null);}
 @Transactional(readOnly=true) public View detail(User user,String id){permission(user);return view(sessions.findByIdAndOwnerId(id,user.getId()).orElseThrow(()->error(404,"Không tìm thấy phiên của bạn")));}
 @Transactional(readOnly=true) public PageResponse<View> history(User user,LocalDate from,LocalDate to,int page,int size){
  permission(user);if(from==null||to==null||to.isBefore(from)||java.time.temporal.ChronoUnit.DAYS.between(from,to)>366)throw error(400,"Chọn khoảng tối đa 366 ngày");
  return PageResponse.from(sessions.findByOwnerIdAndCreatedAtGreaterThanEqualAndCreatedAtLessThanOrderByCreatedAtDescIdDesc(user.getId(),from.atStartOfDay(),to.plusDays(1).atStartOfDay(),PageRequest.of(Math.max(0,page),Math.clamp(size,1,50))).map(this::view));
 }
 @Transactional public View start(User user,Start input){
  permission(user);lockOwner(user);validateOperation(input.operationId());String fingerprint=hash("START:"+json.writeValueAsString(input));var previous=previous(user,input.operationId(),fingerprint);if(previous!=null)return previous;
  if(input.minutes()<1||input.minutes()>180||!Set.of("FOCUS","BREAK").contains(Objects.toString(input.mode(),"")))throw error(400,"Chế độ và thời lượng không hợp lệ");
  if(sessions.findFirstByOwnerIdAndStateInOrderByCreatedAtDesc(user.getId(),ACTIVE).isPresent())throw error(409,"Đang có phiên chạy hoặc tạm dừng. Hãy kết thúc phiên đó trước.");
  var session=new FocusSession();session.setOwnerId(user.getId());session.setMode(input.mode());session.setState("RUNNING");session.setPlannedSeconds(input.minutes()*60);session.setCreatedAt(now());session.setRunningSince(now());session.setCategory("PERSONAL");
  if(input.todoId()!=null&&!input.todoId().isBlank()){
   var todo=todos.findByIdAndUser(input.todoId(),user).orElseThrow(()->error(404,"Không tìm thấy công việc của bạn"));
   if(!Set.of(Todo.TodoStatus.OPEN,Todo.TodoStatus.IN_PROGRESS).contains(todo.getStatus()))throw error(400,"Chọn công việc chưa hoàn thành");
   session.setTodoId(todo.getId());session.setTitle(todo.getTitle());session.setCategory(todo.getCategory().name());
  }else{if(input.title()==null||input.title().isBlank()||input.title().length()>180)throw error(400,"Nhập tên phiên tối đa 180 ký tự");session.setTitle(input.title().trim());}
  var result=view(sessions.saveAndFlush(session));record(user,input.operationId(),fingerprint,result);return result;
 }
 @Transactional public View command(User user,String id,Command input){
  permission(user);lockOwner(user);validateOperation(input.operationId());String fingerprint=hash(id+":"+json.writeValueAsString(input));var previous=previous(user,input.operationId(),fingerprint);if(previous!=null)return previous;
  var session=sessions.locked(id,user.getId()).orElseThrow(()->error(404,"Không tìm thấy phiên của bạn"));
  if(!Objects.equals(session.getVersion(),input.version()))throw error(409,"Phiên đã thay đổi ở thiết bị khác. Tải lại để tiếp tục.");
  if(!ACTIVE.contains(session.getState()))throw error(409,"Phiên đã kết thúc");
  var time=now();boolean longSession=Duration.between(session.getCreatedAt(),time).getSeconds()>MAX_SECONDS;
  if(longSession&&!Set.of("FINISH","CANCEL").contains(Objects.toString(input.action(),"")))throw error(409,"Phiên đã quá 8 giờ. Hãy kết thúc hoặc hủy để xem lại thời gian.");
  int elapsed=elapsed(session,time);
  switch(Objects.toString(input.action(),"")){
   case "PAUSE"->{if(!"RUNNING".equals(session.getState()))throw error(409,"Phiên đang tạm dừng");session.setAccumulatedSeconds(elapsed);session.setRunningSince(null);session.setState("PAUSED");}
   case "RESUME"->{if(!"PAUSED".equals(session.getState()))throw error(409,"Phiên đang chạy");session.setRunningSince(time);session.setState("RUNNING");}
   case "FINISH","CANCEL"->{session.setAccumulatedSeconds(elapsed);session.setRunningSince(null);session.setEndedAt(time);session.setState("FINISH".equals(input.action())?"COMPLETED":"CANCELLED");session.setReviewRequired(longSession);}
   default->throw error(400,"Thao tác không hợp lệ");
  }
  var result=view(sessions.saveAndFlush(session));record(user,input.operationId(),fingerprint,result);return result;
 }
 private int elapsed(FocusSession s,LocalDateTime time){long additional="RUNNING".equals(s.getState())&&s.getRunningSince()!=null?Math.max(0,Duration.between(s.getRunningSince(),time).getSeconds()):0;return (int)Math.min(MAX_SECONDS,Math.max(0,s.getAccumulatedSeconds()+additional));}
 private View view(FocusSession s){var time=now();return new View(s.getId(),s.getTodoId(),s.getTitle(),s.getCategory(),s.getMode(),s.getState(),s.getPlannedSeconds(),elapsed(s,time),s.getCreatedAt(),s.getRunningSince(),s.getEndedAt(),time,s.isReviewRequired()||Duration.between(s.getCreatedAt(),time).getSeconds()>MAX_SECONDS&&ACTIVE.contains(s.getState()),s.getVersion());}
 private void lockOwner(User u){users.findByIdForUpdate(u.getId()).orElseThrow(()->error(404,"Tài khoản không còn tồn tại"));}
 private void validateOperation(String op){if(op==null||!op.matches("[A-Za-z0-9_-]{8,80}"))throw error(400,"Mã thao tác không hợp lệ");}
 private View previous(User u,String operation,String fingerprint){return operations.findByOwnerIdAndOperationId(u.getId(),operation).map(o->{if(!fingerprint.equals(o.getFingerprint()))throw error(409,"Mã thao tác đã dùng với nội dung khác");return json.readValue(o.getResultJson(),View.class);}).orElse(null);}
 private void record(User u,String operation,String fingerprint,View result){var o=new FocusOperation();o.setOwnerId(u.getId());o.setOperationId(operation);o.setFingerprint(fingerprint);o.setResultJson(json.writeValueAsString(result));operations.saveAndFlush(o);}
 private String hash(String value){try{return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(value.getBytes(StandardCharsets.UTF_8)));}catch(Exception e){throw new IllegalStateException(e);}}
 private static ResponseStatusException error(int status,String message){return new ResponseStatusException(HttpStatus.valueOf(status),message);}
}
