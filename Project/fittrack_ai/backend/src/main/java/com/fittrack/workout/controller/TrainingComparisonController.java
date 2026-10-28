package com.fittrack.workout.controller;
import com.fittrack.user.entity.User;
import com.fittrack.workout.service.TrainingComparisonService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import java.time.LocalDate;
@RestController @RequiredArgsConstructor @RequestMapping("/api/workouts/comparison")
public class TrainingComparisonController {
 private final TrainingComparisonService service;
 @GetMapping public TrainingComparisonService.Comparison compare(@AuthenticationPrincipal User user,@RequestParam LocalDate firstFrom,@RequestParam LocalDate firstTo,@RequestParam LocalDate secondFrom,@RequestParam LocalDate secondTo,@RequestParam(required=false)String firstPlan,@RequestParam(required=false)String secondPlan){return service.compare(user,firstFrom,firstTo,secondFrom,secondTo,firstPlan,secondPlan);}
}
