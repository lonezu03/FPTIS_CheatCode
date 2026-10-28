package com.fittrack.workoutplan.controller;
import com.fittrack.workoutplan.service.TrainingProgramService;
import com.fittrack.workoutplan.dto.TrainingProgramDtos.*;
import com.fittrack.workout.dto.WorkoutSessionResponse;
import com.fittrack.common.dto.PageResponse;
import com.fittrack.user.entity.User;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import java.time.*;
import java.util.*;
@RestController @RequestMapping("/api/workout-plans") @RequiredArgsConstructor
public class TrainingProgramController {
 private final TrainingProgramService service;
 private User user(Authentication a){return (User)a.getPrincipal();}
 @GetMapping("/cycles") public PageResponse<CycleResponse> cycles(Authentication a,@RequestParam(defaultValue="0") int page,@RequestParam(defaultValue="12") int size){return service.cycles(user(a),page,size);}
 @PostMapping("/cycles") public CycleResponse create(Authentication a,@Valid @RequestBody CycleRequest r){return service.saveCycle(user(a),null,r);}
 @PutMapping("/cycles/{id}") public CycleResponse update(Authentication a,@PathVariable String id,@Valid @RequestBody CycleRequest r){return service.saveCycle(user(a),id,r);}
 @DeleteMapping("/cycles/{id}") public void delete(Authentication a,@PathVariable String id,@RequestParam Long version){service.deleteCycle(user(a),id,version);}
 @GetMapping("/appointments") public List<AppointmentResponse> appointments(Authentication a,@RequestParam LocalDateTime from,@RequestParam LocalDateTime to){return service.appointments(user(a),from,to);}
 @GetMapping("/appointments/{id}") public AppointmentResponse appointment(Authentication a,@PathVariable String id){return service.appointment(user(a),id);}
 @PostMapping("/appointments") public List<AppointmentResponse> schedule(Authentication a,@Valid @RequestBody AppointmentRequest r){return service.schedule(user(a),r);}
 @DeleteMapping("/appointments/{id}") public void deleteAppointment(Authentication a,@PathVariable String id,@RequestParam Long version){service.deleteAppointment(user(a),id,version);}
 @PostMapping("/appointments/{id}/complete") public WorkoutSessionResponse complete(Authentication a,@PathVariable String id,@Valid @RequestBody Completion r){return service.complete(user(a),id,r);}
}
