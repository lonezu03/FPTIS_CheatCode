package com.fittrack.personaltracking;
import com.fittrack.personaltracking.TrackingDtos.*;
import com.fittrack.user.entity.User;
import com.fittrack.common.dto.PageResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import jakarta.servlet.http.HttpServletRequest;
import java.time.LocalDate;
import java.util.List;

@RestController @RequiredArgsConstructor
@RequestMapping({"/api/health-management/tracking/goals","/api/workouts/goals","/api/todos/habits","/api/health-management/tracking/recovery"})
public class TrackingController {
 private final TrackingService service;
 private String kind(HttpServletRequest r){var p=r.getRequestURI();return p.contains("/habits")?"HABIT":p.contains("/recovery")?"RECOVERY":p.contains("/workouts/")?"WORKOUT_GOAL":"BODY_GOAL";}
 @GetMapping public PageResponse<Response> list(@AuthenticationPrincipal User u,HttpServletRequest req,@RequestParam(defaultValue="false")boolean archived,@RequestParam(defaultValue="0")int page,@RequestParam(defaultValue="15")int size){return service.list(u,kind(req),archived,page,size);}
 @PostMapping public Response create(@AuthenticationPrincipal User u,HttpServletRequest req,@RequestBody Request r){return service.save(u,kind(req),null,r);}
 @PatchMapping("/{id}") public Response edit(@AuthenticationPrincipal User u,HttpServletRequest req,@PathVariable String id,@RequestBody Request r){return service.save(u,kind(req),id,r);}
 @DeleteMapping("/{id}") public void delete(@AuthenticationPrincipal User u,HttpServletRequest req,@PathVariable String id,@RequestParam Long version){service.archive(u,kind(req),id,version);}
 @GetMapping("/{id}/checkins") public List<CheckinResponse> history(@AuthenticationPrincipal User u,HttpServletRequest req,@PathVariable String id,@RequestParam LocalDate from,@RequestParam LocalDate to){return service.history(u,kind(req),id,from,to);}
 @PutMapping("/{id}/checkins/{date}") public CheckinResponse checkin(@AuthenticationPrincipal User u,HttpServletRequest req,@PathVariable String id,@PathVariable LocalDate date,@RequestBody CheckinRequest r){return service.checkin(u,kind(req),id,date,r);}
}
