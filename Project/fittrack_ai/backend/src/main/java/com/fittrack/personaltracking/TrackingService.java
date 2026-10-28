package com.fittrack.personaltracking;
import com.fittrack.personaltracking.TrackingDtos.*;
import com.fittrack.user.entity.User;
import com.fittrack.common.dto.PageResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;
import java.time.*;
import java.util.*;
import java.util.stream.Collectors;

@Service @RequiredArgsConstructor @Transactional
public class TrackingService {
 private final TrackingRepository entries;
 private final TrackingCheckinRepository checkins;
 private final GoalPhaseRepository phases;
 private final com.fittrack.user.repository.UserRepository users;
 private static final ZoneId VN=ZoneId.of("Asia/Ho_Chi_Minh");
 @Transactional(readOnly=true) public PageResponse<Response> list(User u,String kind,boolean archived,int page,int size){
  return PageResponse.from(entries.findByOwnerIdAndKindAndArchivedOrderByStartDateDesc(u.getId(),kind,archived,PageRequest.of(Math.max(0,page),Math.max(1,Math.min(50,size)))).map(this::response));
 }
 public Response save(User u,String kind,String id,Request r){
  if("RECOVERY".equals(kind))users.findByIdForUpdate(u.getId()).orElseThrow();
  var e=id==null?new TrackingEntry():owned(u,kind,id,true);
  if(id!=null&&!Objects.equals(e.getVersion(),r.version()))throw conflict("Dữ liệu đã thay đổi. Vui lòng tải lại.");
  if(r.title()==null||r.title().isBlank()||r.title().length()>160)throw bad("Tên cần từ 1 đến 160 ký tự");
  if(r.note()!=null&&r.note().length()>2000)throw bad("Ghi chú tối đa 2000 ký tự");
  e.setOwnerId(u.getId());e.setKind(kind);e.setTitle(r.title().trim());e.setNote(r.note());
  e.setStartDate(r.startDate()==null?LocalDate.now(VN):r.startDate());e.setTargetDate(r.targetDate());
  if(r.targetDate()!=null&&r.targetDate().isBefore(e.getStartDate()))throw bad("Ngày đích không thể trước ngày bắt đầu");
  e.setArchived(Boolean.TRUE.equals(r.archived()));
  if(kind.endsWith("GOAL")){
   e.setContentRevision(e.getContentRevision()+1);
   if(!validNumber(r.baseline())||!validNumber(r.target()))throw bad("Nhập số đo ban đầu và mục tiêu hợp lệ (tối đa 15 chữ số nguyên, 3 thập phân)");
   if(r.metric()==null||r.metric().isBlank()||r.metric().length()>40||r.unit()==null||r.unit().isBlank()||r.unit().length()>20)throw bad("Nhập chỉ số và đơn vị");
   e.setMetric(r.metric());e.setUnit(r.unit());e.setBaseline(r.baseline());e.setTarget(r.target());
   if(r.phases()!=null&&r.phases().size()>24)throw bad("Tối đa 24 giai đoạn");
  }
  if("HABIT".equals(kind)){
   var days=r.weekdays()==null?List.<Integer>of():r.weekdays();
   if(days.stream().anyMatch(d->d==null||d<1||d>7))throw bad("Ngày trong tuần phải từ 1 đến 7");
   e.setWeekdays(days.stream().distinct().sorted().map(String::valueOf).collect(Collectors.joining(",")));
  }
  if("RECOVERY".equals(kind)){
   if(r.sleepStart()==null||r.sleepEnd()==null||!r.sleepEnd().isAfter(r.sleepStart())||Duration.between(r.sleepStart(),r.sleepEnd()).toMinutes()>1440)throw bad("Khoảng ngủ phải lớn hơn 0 và không quá 24 giờ");
   if(r.sleepEnd().isAfter(LocalDateTime.now(VN).plusMinutes(5)))throw bad("Không ghi giấc ngủ trong tương lai");
   if(entries.overlaps(u.getId(),id==null?"":id,r.sleepStart(),r.sleepEnd())>0)throw conflict("Khoảng ngủ bị trùng với bản ghi khác");
   for(Integer rating:Arrays.asList(r.quality(),r.fatigue(),r.soreness()))if(rating!=null&&(rating<1||rating>5))throw bad("Mức đánh giá phải từ 1 đến 5 hoặc để trống");
   e.setSleepStart(r.sleepStart());e.setSleepEnd(r.sleepEnd());e.setQuality(r.quality());e.setFatigue(r.fatigue());e.setSoreness(r.soreness());e.setStartDate(r.sleepEnd().toLocalDate());
  }
  entries.saveAndFlush(e);
  if(kind.endsWith("GOAL")){
   phases.deleteByGoalId(e.getId());phases.flush();int position=0;LocalDate previous=e.getStartDate();
   for(var p:r.phases()==null?List.<Phase>of():r.phases()){
    if(p.title()==null||p.title().isBlank()||p.title().length()>120||!validNumber(p.target())||p.targetDate()==null||p.targetDate().isBefore(previous)||(e.getTargetDate()!=null&&p.targetDate().isAfter(e.getTargetDate())))throw bad("Giai đoạn cần tên, mục tiêu và ngày theo thứ tự trong khoảng mục tiêu");
    var phase=new GoalPhase();phase.setGoalId(e.getId());phase.setTitle(p.title());phase.setTargetDate(p.targetDate());phase.setTarget(p.target());phase.setPosition(position++);phases.save(phase);previous=p.targetDate();
   }
  }
  return response(e);
 }
 public void archive(User u,String kind,String id,Long version){var e=owned(u,kind,id,true);if(!Objects.equals(e.getVersion(),version))throw conflict("Dữ liệu đã thay đổi");e.setArchived(true);}
 @Transactional(readOnly=true) public List<CheckinResponse> history(User u,String kind,String id,LocalDate from,LocalDate to){owned(u,kind,id,false);range(from,to);return checkins.findByEntryIdAndDayBetweenOrderByDayAsc(id,from,to).stream().map(this::response).toList();}
 public CheckinResponse checkin(User u,String kind,String id,LocalDate day,CheckinRequest r){
  if("RECOVERY".equals(kind))throw bad("Giấc ngủ được chỉnh trực tiếp, không có ghi nhận số đo riêng");
  var e=owned(u,kind,id,true);if(e.isArchived())throw bad("Mục đã lưu trữ");if(day.isAfter(LocalDate.now(VN))||day.isBefore(e.getStartDate()))throw bad("Ngày ghi nhận không hợp lệ");
  if(r.note()!=null&&r.note().length()>1000||r.evidence()!=null&&r.evidence().length()>500)throw bad("Ghi chú hoặc minh chứng quá dài");
  if("HABIT".equals(kind)){
   if(!Set.of("DONE","SKIPPED").contains(Objects.toString(r.status(),"")))throw bad("Trạng thái không hợp lệ");
   if(e.getWeekdays()!=null&&!e.getWeekdays().isBlank()&&!Arrays.asList(e.getWeekdays().split(",")).contains(String.valueOf(day.getDayOfWeek().getValue())))throw bad("Ngày này không nằm trong lịch thói quen");
  }else if(!validNumber(r.value()))throw bad("Nhập giá trị đo hợp lệ; dữ liệu thiếu không phải số 0");
  var c=checkins.findByEntryIdAndDay(id,day).orElseGet(TrackingCheckin::new);c.setEntryId(id);c.setDay(day);c.setStatus("HABIT".equals(kind)?r.status():"RECORDED");c.setValue(r.value());c.setNote(r.note());c.setEvidence(r.evidence());return response(checkins.save(c));
 }
 private TrackingEntry owned(User u,String kind,String id,boolean lock){return (lock?entries.lock(id,u.getId(),kind):entries.findByIdAndOwnerIdAndKind(id,u.getId(),kind)).orElseThrow(()->new ResponseStatusException(HttpStatus.NOT_FOUND,"Không tìm thấy mục của bạn"));}
 private Response response(TrackingEntry e){return new Response(e.getId(),e.getKind(),e.getTitle(),e.getNote(),e.getMetric(),e.getUnit(),e.getBaseline(),e.getTarget(),e.getStartDate(),e.getTargetDate(),e.getWeekdays()==null||e.getWeekdays().isBlank()?List.of():Arrays.stream(e.getWeekdays().split(",")).map(Integer::parseInt).toList(),e.getSleepStart(),e.getSleepEnd(),e.getQuality(),e.getFatigue(),e.getSoreness(),e.isArchived(),e.getVersion(),e.getKind().endsWith("GOAL")?phases.findByGoalIdOrderByPositionAsc(e.getId()).stream().map(p->new Phase(p.getTitle(),p.getTargetDate(),p.getTarget())).toList():List.of());}
 private CheckinResponse response(TrackingCheckin c){return new CheckinResponse(c.getId(),c.getDay(),c.getStatus(),c.getValue(),c.getNote(),c.getEvidence());}
 private static void range(LocalDate from,LocalDate to){if(from==null||to==null||to.isBefore(from)||java.time.temporal.ChronoUnit.DAYS.between(from,to)>366)throw bad("Khoảng lịch sử tối đa 366 ngày");}
 private static boolean validNumber(java.math.BigDecimal v){return v!=null&&v.scale()<=3&&v.precision()-v.scale()<=15;}
 private static ResponseStatusException bad(String m){return new ResponseStatusException(HttpStatus.BAD_REQUEST,m);}
 private static ResponseStatusException conflict(String m){return new ResponseStatusException(HttpStatus.CONFLICT,m);}
}
