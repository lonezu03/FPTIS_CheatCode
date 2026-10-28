package com.fittrack.workoutplan.service;
import com.fittrack.workoutplan.dto.*;
import com.fittrack.workoutplan.dto.TrainingProgramDtos.*;
import com.fittrack.workoutplan.entity.*;
import com.fittrack.workoutplan.repository.*;
import com.fittrack.workout.service.WorkoutService;
import com.fittrack.workout.repository.WorkoutSessionRepository;
import com.fittrack.workout.mapper.WorkoutMapper;
import com.fittrack.workout.dto.WorkoutSessionResponse;
import com.fittrack.user.entity.User;
import com.fittrack.common.dto.PageResponse;
import com.fittrack.schedule.dto.ScheduleDtos.CalendarEntryResponse;
import tools.jackson.databind.ObjectMapper;
import tools.jackson.core.type.TypeReference;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;
import java.time.*;
import java.util.*;
@Service @RequiredArgsConstructor @Transactional
public class TrainingProgramService {
 private final TrainingCycleRepository cycles;
 private final TrainingAppointmentRepository appointments;
 private final WorkoutPlanService plans;
 private final WorkoutService workouts;
 private final WorkoutSessionRepository sessions;
 private final WorkoutMapper workoutMapper;
 private final ObjectMapper json;
 public PageResponse<CycleResponse> cycles(User user,int page,int size) {
  return PageResponse.from(cycles.findByUserOrderByStartDateDesc(user,PageRequest.of(Math.max(0,page),Math.max(1,Math.min(50,size)))).map(this::cycleResponse));
 }
 public CycleResponse saveCycle(User user,String id,CycleRequest request) {
  if(request.weeks()==null || request.weeks().size()<4 || request.weeks().size()>12) throw new IllegalArgumentException("Chu kỳ phải có 4–12 tuần");
  for(int i=0;i<request.weeks().size();i++) if(request.weeks().get(i)==null || request.weeks().get(i).number()!=i+1 || request.weeks().get(i).targetSessions()<1 || request.weeks().get(i).targetSessions()>14) throw new IllegalArgumentException("Tuần phải liên tục và chỉ tiêu 1–14 buổi");
  TrainingCycle cycle=id==null?new TrainingCycle():cycles.findByIdAndUser(id,user).orElseThrow(()->new IllegalArgumentException("Không tìm thấy chu kỳ"));
  if(id!=null && !Objects.equals(cycle.getVersion(),request.version())) throw conflict("Chu kỳ đã thay đổi, vui lòng tải lại");
  if(id!=null && !appointments.findByUserAndCycleIdOrderByStartAtAsc(user,id).isEmpty() && !cycle.getStartDate().equals(request.startDate())) throw new IllegalArgumentException("Chu kỳ đã lên lịch: giữ ngày bắt đầu, hoặc tạo chu kỳ mới");
  if(id!=null && appointments.findByUserAndCycleIdOrderByStartAtAsc(user,id).stream().anyMatch(a->a.getWeekNumber()!=null&&a.getWeekNumber()>request.weeks().size())) throw new IllegalArgumentException("Không rút ngắn chu kỳ qua những tuần đã có lịch");
  cycle.setUser(user); cycle.setName(request.name().trim()); cycle.setStartDate(request.startDate());cycle.setWeeksJson(write(request.weeks()));
  return cycleResponse(cycles.saveAndFlush(cycle));
 }
 public void deleteCycle(User user,String id,Long version) {
  TrainingCycle cycle=cycles.findByIdAndUser(id,user).orElseThrow(()->new IllegalArgumentException("Không tìm thấy chu kỳ"));
  if(!Objects.equals(version,cycle.getVersion())) throw conflict("Chu kỳ đã thay đổi");
  // Calendar snapshots/history remain accessible without the deleted template.
  cycles.delete(cycle);
 }
 public List<AppointmentResponse> appointments(User user,LocalDateTime from,LocalDateTime to) {
  requireSchedule(user); range(from,to);
  return appointments.findByUserAndStartAtGreaterThanEqualAndStartAtLessThanOrderByStartAtAsc(user,from,to).stream().map(this::appointmentResponse).toList();
 }
 public AppointmentResponse appointment(User user,String id) {
  requireSchedule(user); return appointmentResponse(owned(user,id));
 }
 public List<AppointmentResponse> schedule(User user,AppointmentRequest request) {
  requireSchedule(user);
  var plan=plans.getPlanDetail(user,request.planId());
  var day=plan.getDays().stream().filter(d->d.getId().equals(request.dayId())).findFirst().orElseThrow(()->new IllegalArgumentException("Không tìm thấy ngày tập"));
  int repeat=request.repeatWeeks()==null?1:request.repeatWeeks();
  if(repeat<1 || repeat>12) throw new IllegalArgumentException("Chỉ lên lịch tối đa 12 tuần mỗi lần");
  TrainingCycle cycle=request.cycleId()==null||request.cycleId().isBlank()?null:cycles.findByIdAndUser(request.cycleId(),user).orElseThrow(()->new IllegalArgumentException("Không tìm thấy chu kỳ"));
  var weeks=cycle==null?List.<Week>of():readWeeks(cycle.getWeeksJson());
  List<AppointmentResponse> result=new ArrayList<>();
  for(int i=0;i<repeat;i++) {
   LocalDateTime start=request.startAt().plusWeeks(i);
   Integer number=null;
   if(cycle!=null) {
    long days=java.time.temporal.ChronoUnit.DAYS.between(cycle.getStartDate(),start.toLocalDate());
    number=(int)Math.floorDiv(days,7)+1;
    if(number<1 || number>weeks.size()) throw new IllegalArgumentException("Lịch nằm ngoài chu kỳ");
    if(i==0 && request.weekNumber()!=null && !request.weekNumber().equals(number)) throw new IllegalArgumentException("Số tuần không khớp ngày bắt đầu");
   }
   TrainingAppointment a=new TrainingAppointment(); a.setUser(user);
   String title=plan.getName()+" · "+day.getName();a.setTitle(title.length()>255?title.substring(0,252)+"...":title);
   a.setPlanId(plan.getId());a.setStartAt(start);a.setCycleId(cycle==null?null:cycle.getId());a.setWeekNumber(number);a.setSnapshotJson(write(day));
   result.add(appointmentResponse(appointments.save(a)));
  }
  return result;
 }
 public void deleteAppointment(User user,String id,Long version) {
  requireSchedule(user);var a=appointments.lockOwned(id,user).orElseThrow(()->new IllegalArgumentException("Không tìm thấy lịch tập"));
  if(!Objects.equals(version,a.getVersion())) throw conflict("Lịch tập đã thay đổi");
  if(a.getCompletedSessionId()!=null) throw conflict("Buổi tập đã hoàn thành; chỉnh lịch sử thay vì xóa lịch");
  appointments.delete(a);
 }
 public WorkoutSessionResponse complete(User user,String id,Completion request) {
  requireSchedule(user);
  var a=appointments.lockOwned(id,user).orElseThrow(()->new IllegalArgumentException("Không tìm thấy lịch tập"));
  if(a.getCompletedSessionId()!=null) return sessions.findByIdAndUser(a.getCompletedSessionId(),user)
    .map(workoutMapper::toWorkoutSessionResponse).orElseThrow(()->conflict("Buổi thực tế đã bị xóa; lịch vẫn giữ dấu hoàn thành"));
  if(request==null || request.session()==null || request.session().getSessionDate()==null
     || request.session().getSets()==null || request.session().getSets().stream().noneMatch(s->s!=null
       && Boolean.TRUE.equals(s.getCompleted()) && s.getSetType()!=com.fittrack.workout.entity.WorkoutSetType.WARMUP
       && s.getReps()!=null && s.getReps()>0 && s.getWeight()!=null && Double.isFinite(s.getWeight()) && s.getWeight()>=0))
     throw new IllegalArgumentException("Cần ngày tập và ít nhất một hiệp chính thực tế đã hoàn thành");
  var result=workouts.createSession(user,request.session());
  a.setCompletedSessionId(result.getId());a.setCompletedAt(LocalDateTime.now(ZoneId.of("Asia/Ho_Chi_Minh")));
  appointments.saveAndFlush(a);
  return result;
 }
 public List<CalendarEntryResponse> calendar(User user,LocalDateTime from,LocalDateTime to) {
  if(!Boolean.TRUE.equals(user.getFitnessEnabled()) && !"ADMIN".equalsIgnoreCase(user.getRole())) return List.of();
  range(from,to);
  return appointments.findByUserAndStartAtGreaterThanEqualAndStartAtLessThanOrderByStartAtAsc(user,from,to).stream()
   .map(a->new CalendarEntryResponse("WORKOUT:"+a.getId(),"WORKOUT",a.getId(),a.getTitle(),"Mở để tập theo snapshot đã lên lịch","FITNESS",a.getStartAt(),null,a.getCompletedSessionId()==null?"PLANNED":"DONE",false)).toList();
 }
 private TrainingAppointment owned(User u,String id) {return appointments.findByIdAndUser(id,u).orElseThrow(()->new IllegalArgumentException("Không tìm thấy lịch tập"));}
 private CycleResponse cycleResponse(TrainingCycle c) {
  var all=appointments.findByUserAndCycleIdOrderByStartAtAsc(c.getUser(),c.getId());
  return new CycleResponse(c.getId(),c.getName(),c.getStartDate(),c.getVersion(),readWeeks(c.getWeeksJson()),all.size(),(int)all.stream().filter(a->a.getCompletedSessionId()!=null).count(),all.stream().filter(a->a.getCompletedSessionId()!=null&&a.getWeekNumber()!=null).collect(java.util.stream.Collectors.groupingBy(TrainingAppointment::getWeekNumber,java.util.stream.Collectors.counting())));
 }
 private AppointmentResponse appointmentResponse(TrainingAppointment a) {
  try {return new AppointmentResponse(a.getId(),a.getTitle(),a.getPlanId(),a.getCycleId(),a.getWeekNumber(),a.getStartAt(),a.getVersion(),json.readValue(a.getSnapshotJson(),WorkoutPlanDayResponse.class),a.getCompletedSessionId(),a.getCompletedAt());}
  catch(Exception e){throw new IllegalStateException("Không đọc được snapshot lịch tập",e);}
 }
 private List<Week> readWeeks(String s){try{return json.readValue(s,new TypeReference<List<Week>>(){});}catch(Exception e){throw new IllegalStateException("Không đọc được chu kỳ",e);}}
 private String write(Object value){try{return json.writeValueAsString(value);}catch(Exception e){throw new IllegalStateException("Không lưu được snapshot",e);}}
 private void range(LocalDateTime f,LocalDateTime t){if(f==null||t==null||!f.isBefore(t)||Duration.between(f,t).toDays()>370)throw new IllegalArgumentException("Khoảng xem tối đa 370 ngày");}
 private void requireSchedule(User u){if(!Boolean.TRUE.equals(u.getScheduleEnabled())&&!"ADMIN".equalsIgnoreCase(u.getRole()))throw new ResponseStatusException(HttpStatus.FORBIDDEN,"Cần quyền thời khóa biểu");}
 private ResponseStatusException conflict(String s){return new ResponseStatusException(HttpStatus.CONFLICT,s);}
}
