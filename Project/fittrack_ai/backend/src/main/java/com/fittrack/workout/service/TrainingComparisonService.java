package com.fittrack.workout.service;
import com.fittrack.user.entity.User;
import com.fittrack.workout.entity.WorkoutSet;
import com.fittrack.workout.repository.TrainingComparisonRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.time.*;
import java.time.temporal.ChronoUnit;
import java.util.*;

@Service @RequiredArgsConstructor @Transactional(readOnly=true)
public class TrainingComparisonService {
 private final TrainingComparisonRepository repository;
 public record ExerciseMetric(String exerciseId,String name,int sets,double volume,Double bestWeight,Double estimated1rm){}
 public record Period(LocalDate from,LocalDate to,String planId,int completedSessions,int trainingDays,int workingSets,double volume,Long plannedSessions,Double adherence,List<ExerciseMetric> exercises){}
 public record Comparison(Period first,Period second,String disclaimer){}
 public Comparison compare(User user,LocalDate firstFrom,LocalDate firstTo,LocalDate secondFrom,LocalDate secondTo,String firstPlan,String secondPlan){
  long days=range(firstFrom,firstTo);if(range(secondFrom,secondTo)!=days)throw new IllegalArgumentException("Hai khoảng so sánh cần cùng số ngày");
  return new Comparison(period(user,firstFrom,firstTo,firstPlan),period(user,secondFrom,secondTo,secondPlan),"Chỉ hiệp chính đã hoàn thành. So sánh giáo án chỉ dùng buổi có liên kết thực tế; không suy đoán lịch sử theo tên. Chưa có dữ liệu không có nghĩa hiệu quả bằng 0. e1RM là ước tính tập luyện, không phải kết luận y khoa.");
 }
 private Period period(User u,LocalDate from,LocalDate to,String plan){
  String id=plan==null?"":plan;
  var sets=repository.sets(u.getId(),from,to,id,from.atStartOfDay(),to.plusDays(1).atStartOfDay(),org.springframework.data.domain.PageRequest.of(0,50001));
  if(sets.size()>50000)throw new IllegalArgumentException("Quá 50000 hiệp, hãy thu hẹp khoảng so sánh");
  Long planned=id.isBlank()?null:repository.planned(u.getId(),id,from.atStartOfDay(),to.plusDays(1).atStartOfDay());
  return summarize(sets,from,to,plan,planned);
 }
 public static Period summarize(List<WorkoutSet> sets,LocalDate from,LocalDate to,String plan,Long planned){
  var filtered=sets.stream().filter(s->Boolean.TRUE.equals(s.getCompleted())&&s.getSetType()!=com.fittrack.workout.entity.WorkoutSetType.WARMUP).toList();
  var groups=new LinkedHashMap<String,List<WorkoutSet>>();filtered.forEach(s->groups.computeIfAbsent(s.getExercise().getId(),k->new ArrayList<>()).add(s));
  var metrics=new ArrayList<ExerciseMetric>();
  groups.forEach((id,values)->metrics.add(new ExerciseMetric(id,values.getFirst().getExercise().getName(),values.size(),values.stream().mapToDouble(TrainingComparisonService::volume).sum(),values.stream().map(WorkoutSet::getWeight).filter(Objects::nonNull).max(Double::compare).orElse(null),values.stream().filter(s->s.getReps()!=null&&s.getReps()>=1&&s.getReps()<=30&&s.getWeight()!=null&&s.getWeight()>0).map(s->s.getWeight()*(1+s.getReps()/30.0)).max(Double::compare).orElse(null))));
  int sessions=(int)filtered.stream().map(s->s.getSession().getId()).distinct().count();
  return new Period(from,to,plan,sessions,(int)filtered.stream().map(s->s.getSession().getSessionDate()).distinct().count(),filtered.size(),filtered.stream().mapToDouble(TrainingComparisonService::volume).sum(),planned,planned==null||planned==0?null:100.0*sessions/planned,metrics);
 }
 private static double volume(WorkoutSet s){return s.getWeight()==null||s.getReps()==null?0:s.getWeight()*s.getReps();}
 private static long range(LocalDate from,LocalDate to){if(from==null||to==null||to.isBefore(from)||ChronoUnit.DAYS.between(from,to)>=366)throw new IllegalArgumentException("Khoảng so sánh từ 1 đến 366 ngày");return ChronoUnit.DAYS.between(from,to);}
}
