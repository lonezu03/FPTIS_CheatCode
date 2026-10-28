package com.fittrack.personalreport;
import com.fittrack.user.entity.User;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import java.time.LocalDate;
import java.util.Set;
@RestController @RequestMapping("/api/personal-reports") @RequiredArgsConstructor
public class PersonalMonthlyReportController {
 private final PersonalMonthlyReportService service;
 @GetMapping("/monthly") public PersonalMonthlyReportService.Report monthly(@AuthenticationPrincipal User user,@RequestParam LocalDate month,@RequestParam Set<String> sections){return service.report(user,month,sections);}
}
