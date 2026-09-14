package com.fittrack.recommendation.service;

import com.fittrack.recommendation.dto.WeeklyCoachDtos.WeeklyCheckInResponse;
import com.fittrack.recommendation.entity.WeeklyCheckIn;
import com.fittrack.recommendation.repository.WeeklyCheckInRepository;
import com.fittrack.report.dto.WeeklyReportResponse;
import com.fittrack.report.service.WeeklyReportService;
import com.fittrack.user.entity.User;
import com.fittrack.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.temporal.TemporalAdjusters;
import java.util.List;
import java.util.Set;

@Service
@RequiredArgsConstructor
public class WeeklyCoachService {
    private static final ZoneId BUSINESS_ZONE = ZoneId.of("Asia/Ho_Chi_Minh");
    private static final Set<String> DECISIONS = Set.of("ACCEPTED", "IGNORED");

    private final WeeklyCheckInRepository repository;
    private final WeeklyReportService reportService;
    private final UserRepository userRepository;

    @Transactional
    public WeeklyCheckInResponse current(User user, LocalDate requestedWeekStart) {
        LocalDate weekStart = requestedWeekStart == null
                ? defaultCompletedWeekStart()
                : requestedWeekStart.with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY));
        WeeklyCheckIn checkIn = repository.findByUserAndWeekStart(user, weekStart)
                .orElseGet(() -> build(user, weekStart));
        return response(repository.save(checkIn));
    }

    @Transactional(readOnly = true)
    public List<WeeklyCheckInResponse> history(User user) {
        return repository.findByUserOrderByWeekStartDesc(user).stream()
                .map(this::response).toList();
    }

    @Transactional
    public WeeklyCheckInResponse decide(User user, String id, String rawDecision) {
        String decision = rawDecision == null ? "" : rawDecision.trim().toUpperCase();
        if ("ACCEPT".equals(decision)) decision = "ACCEPTED";
        if ("IGNORE".equals(decision)) decision = "IGNORED";
        if (!DECISIONS.contains(decision)) {
            throw new IllegalArgumentException("Quyết định phải là ACCEPTED hoặc IGNORED");
        }
        WeeklyCheckIn checkIn = repository.findByIdAndUser(id, user)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy check-in tuần"));
        if (!"PENDING".equals(checkIn.getStatus())) {
            return response(checkIn);
        }
        if ("ACCEPTED".equals(decision)) {
            if (!Boolean.TRUE.equals(checkIn.getDataSufficient())) {
                throw new IllegalStateException("Chưa đủ dữ liệu để áp dụng mục tiêu mới");
            }
            user.setCalorieTargetOverride(checkIn.getProposedCalories());
            user.setProteinTargetOverride(checkIn.getProposedProtein());
            userRepository.save(user);
        }
        checkIn.setStatus(decision);
        checkIn.setDecidedAt(LocalDateTime.now(BUSINESS_ZONE));
        return response(repository.save(checkIn));
    }

    private WeeklyCheckIn build(User user, LocalDate weekStart) {
        LocalDate weekEnd = weekStart.plusDays(6);
        WeeklyReportResponse report = reportService.getWeeklyReport(user, weekStart, weekEnd);
        boolean sufficient = Boolean.TRUE.equals(report.getNutritionDataSufficient());
        double currentCalories = safe(report.getTargetCalories());
        double currentProtein = safe(report.getTargetProtein());
        double proposedCalories = currentCalories;
        String rationale;

        if (!sufficient) {
            rationale = "Chưa đủ dữ liệu: mới có " + safeInt(report.getCompleteNutritionDays())
                    + "/" + safeInt(report.getPeriodDays())
                    + " ngày dinh dưỡng hoàn chỉnh. FitTrack không thay đổi mục tiêu để tránh điều chỉnh sai.";
        } else if (report.getWeightChange() == null) {
            rationale = "Dữ liệu dinh dưỡng đã đủ nhưng chưa có xu hướng cân nặng. Giữ nguyên mục tiêu và ghi cân ít nhất hai lần mỗi tuần.";
        } else {
            double change = report.getWeightChange();
            String goal = user.getGoal() == null ? "MAINTAIN" : user.getGoal().toUpperCase();
            if ("CUT".equals(goal) && change > -0.1) {
                proposedCalories -= 150;
                rationale = "Cân nặng chưa giảm theo mục tiêu trong khi dữ liệu ghi nhận đủ. Đề xuất giảm nhẹ 150 kcal/ngày.";
            } else if ("CUT".equals(goal) && change < -0.7) {
                proposedCalories += 150;
                rationale = "Cân nặng giảm nhanh hơn vùng thận trọng. Đề xuất tăng nhẹ 150 kcal/ngày để hỗ trợ phục hồi.";
            } else if ("LEAN_BULK".equals(goal) && change < 0.05) {
                proposedCalories += 150;
                rationale = "Cân nặng gần như chưa tăng. Đề xuất tăng nhẹ 150 kcal/ngày.";
            } else if ("LEAN_BULK".equals(goal) && change > 0.5) {
                proposedCalories -= 150;
                rationale = "Cân nặng tăng nhanh. Đề xuất giảm nhẹ 150 kcal/ngày và theo dõi vòng eo.";
            } else if ("MAINTAIN".equals(goal) && change > 0.5) {
                proposedCalories -= 150;
                rationale = "Cân nặng tăng ngoài vùng duy trì. Đề xuất giảm nhẹ 150 kcal/ngày.";
            } else if ("MAINTAIN".equals(goal) && change < -0.5) {
                proposedCalories += 150;
                rationale = "Cân nặng giảm ngoài vùng duy trì. Đề xuất tăng nhẹ 150 kcal/ngày.";
            } else {
                rationale = "Xu hướng tuần đang phù hợp với mục tiêu. Tiếp tục mức năng lượng và protein hiện tại.";
            }
        }

        proposedCalories = Math.max(800, Math.min(10000, proposedCalories));
        return WeeklyCheckIn.builder()
                .user(user)
                .weekStart(weekStart)
                .weekEnd(weekEnd)
                .status("PENDING")
                .dataSufficient(sufficient)
                .confidencePercent(safe(report.getNutritionConfidencePercent()))
                .completeDays(safeInt(report.getCompleteNutritionDays()))
                .workoutDays(safeInt(report.getWorkoutDays()))
                .weightChange(report.getWeightChange())
                .currentCalories(round(currentCalories))
                .proposedCalories(round(proposedCalories))
                .currentProtein(round(currentProtein))
                .proposedProtein(round(currentProtein))
                .rationale(rationale)
                .build();
    }

    private WeeklyCheckInResponse response(WeeklyCheckIn value) {
        boolean changed = Math.abs(value.getCurrentCalories() - value.getProposedCalories()) >= 1
                || Math.abs(value.getCurrentProtein() - value.getProposedProtein()) >= 0.1;
        return new WeeklyCheckInResponse(
                value.getId(), value.getWeekStart(), value.getWeekEnd(), value.getStatus(),
                Boolean.TRUE.equals(value.getDataSufficient()), value.getConfidencePercent(),
                value.getCompleteDays(), value.getWorkoutDays(), value.getWeightChange(),
                value.getCurrentCalories(), value.getProposedCalories(), value.getCurrentProtein(),
                value.getProposedProtein(), value.getRationale(),
                "PENDING".equals(value.getStatus()) && Boolean.TRUE.equals(value.getDataSufficient()) && changed,
                value.getDecidedAt()
        );
    }

    private LocalDate defaultCompletedWeekStart() {
        LocalDate today = LocalDate.now(BUSINESS_ZONE);
        return today.with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY)).minusWeeks(1);
    }

    private double safe(Double value) {
        return value == null ? 0 : value;
    }

    private int safeInt(Integer value) {
        return value == null ? 0 : value;
    }

    private double round(double value) {
        return Math.round(value * 10.0) / 10.0;
    }
}
