package com.fittrack.recommendation.service;

import com.fittrack.recommendation.dto.RecommendationItemResponse;
import com.fittrack.recommendation.dto.WeeklyRecommendationResponse;
import com.fittrack.report.dto.WeeklyReportResponse;
import com.fittrack.report.service.WeeklyReportService;
import com.fittrack.user.entity.User;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
public class RecommendationService {

    private final WeeklyReportService weeklyReportService;

    public WeeklyRecommendationResponse getWeeklyRecommendations(User user, LocalDate fromDate, LocalDate toDate) {
        WeeklyReportResponse report = weeklyReportService.getWeeklyReport(user, fromDate, toDate);

        List<RecommendationItemResponse> items = new ArrayList<>();

        if (Boolean.TRUE.equals(report.getNutritionDataSufficient())) {
            analyzeCalories(report, items);
            analyzeProtein(report, items);
        } else {
            items.add(RecommendationItemResponse.builder()
                    .type("DATA_QUALITY")
                    .severity("MEDIUM")
                    .title("Chưa đủ dữ liệu dinh dưỡng")
                    .message("FitTrack chưa thể kết luận bạn ăn thiếu hay chỉ ghi thiếu.")
                    .action("Xác nhận ngày đã ghi đầy đủ sau khi hoàn tất nhật ký. Hiện có "
                            + safeInt(report.getCompleteNutritionDays()) + "/"
                            + safeInt(report.getPeriodDays()) + " ngày đầy đủ.")
                    .build());
        }
        analyzeWorkout(report, items);
        analyzeWeightAndWaist(report, items);

        if (items.isEmpty()) {
            items.add(RecommendationItemResponse.builder()
                    .type("GENERAL")
                    .severity("LOW")
                    .title("Một tuần khá cân bằng")
                    .message("Dinh dưỡng và tập luyện của bạn đang khá cân bằng.")
                    .action("Tiếp tục kế hoạch hiện tại và duy trì ghi nhận dữ liệu đều đặn.")
                    .build());
        }

        return WeeklyRecommendationResponse.builder()
                .fromDate(report.getFromDate())
                .toDate(report.getToDate())
                .summary(buildSummary(report))
                .nutritionDataSufficient(report.getNutritionDataSufficient())
                .completeNutritionDays(report.getCompleteNutritionDays())
                .periodDays(report.getPeriodDays())
                .nutritionConfidencePercent(report.getNutritionConfidencePercent())
                .recommendations(items)
                .build();
    }

    private void analyzeCalories(WeeklyReportResponse report, List<RecommendationItemResponse> items) {
        double avg = safe(report.getAverageCalories());
        double target = safe(report.getTargetCalories());

        if (target <= 0) {
            return;
        }

        double diff = avg - target;

        if (avg < target * 0.85) {
            items.add(RecommendationItemResponse.builder()
                    .type("NUTRITION")
                    .severity("HIGH")
                    .title("Năng lượng nạp vào quá thấp")
                    .message("Năng lượng trung bình đang thấp hơn đáng kể so với mục tiêu.")
                    .action("Tăng khoảng " + round(Math.abs(diff)) + " kcal mỗi ngày. Có thể bổ sung cơm, khoai lang, sữa, dầu ô liu hoặc tăng khẩu phần.")
                    .build());
        } else if (avg > target * 1.10) {
            items.add(RecommendationItemResponse.builder()
                    .type("NUTRITION")
                    .severity("MEDIUM")
                    .title("Năng lượng nạp vào vượt mục tiêu")
                    .message("Năng lượng trung bình đang cao hơn mục tiêu hiện tại.")
                    .action("Giảm khoảng " + round(diff) + " kcal mỗi ngày. Bắt đầu bằng cách giảm đồ ăn vặt, nước ngọt hoặc dầu ăn dư thừa.")
                    .build());
        } else {
            items.add(RecommendationItemResponse.builder()
                    .type("NUTRITION")
                    .severity("LOW")
                    .title("Năng lượng đang đúng hướng")
                    .message("Năng lượng trung bình đang gần với mục tiêu.")
                    .action("Duy trì cấu trúc bữa ăn hiện tại trong tuần tới.")
                    .build());
        }
    }

    private void analyzeProtein(WeeklyReportResponse report, List<RecommendationItemResponse> items) {
        double avg = safe(report.getAverageProtein());
        double target = safe(report.getTargetProtein());

        if (target <= 0) {
            return;
        }

        double missing = target - avg;

        if (avg < target * 0.85) {
            items.add(RecommendationItemResponse.builder()
                    .type("PROTEIN")
                    .severity("HIGH")
                    .title("Lượng protein quá thấp")
                    .message("Lượng protein trung bình đang thấp hơn mục tiêu.")
                    .action("Bổ sung khoảng " + round(missing) + " g protein mỗi ngày, chẳng hạn từ ức gà, trứng, sữa chua Hy Lạp hoặc whey.")
                    .build());
        } else if (avg < target) {
            items.add(RecommendationItemResponse.builder()
                    .type("PROTEIN")
                    .severity("MEDIUM")
                    .title("Lượng protein hơi thấp")
                    .message("Bạn đã gần đạt mục tiêu protein nhưng vẫn còn thiếu.")
                    .action("Bổ sung một khẩu phần protein nhỏ mỗi ngày như trứng, sữa chua hoặc thịt gà.")
                    .build());
        } else {
            items.add(RecommendationItemResponse.builder()
                    .type("PROTEIN")
                    .severity("LOW")
                    .title("Đã đạt mục tiêu protein")
                    .message("Lượng protein trong tuần đang ở mức tốt.")
                    .action("Duy trì lượng protein và điều chỉnh năng lượng qua tinh bột hoặc chất béo nếu cần.")
                    .build());
        }
    }

    private void analyzeWorkout(WeeklyReportResponse report, List<RecommendationItemResponse> items) {
        int workoutDays = safeInt(report.getWorkoutDays());

        if (workoutDays < 3) {
            items.add(RecommendationItemResponse.builder()
                    .type("TRAINING")
                    .severity("HIGH")
                    .title("Tần suất tập luyện còn thấp")
                    .message("Bạn tập ít hơn 3 ngày trong tuần.")
                    .action("Hãy đặt mục tiêu ít nhất 3 buổi trong tuần tới, ví dụ: thân trên đẩy, thân trên kéo và chân hoặc 3 buổi toàn thân.")
                    .build());
        } else if (workoutDays <= 4) {
            items.add(RecommendationItemResponse.builder()
                    .type("TRAINING")
                    .severity("LOW")
                    .title("Tần suất tập luyện phù hợp")
                    .message("Bạn đã tập đủ số ngày để duy trì tiến bộ.")
                    .action("Tập trung tăng tiến dần: thêm số lần lặp, số hiệp hoặc tăng nhẹ mức tạ.")
                    .build());
        } else {
            items.add(RecommendationItemResponse.builder()
                    .type("TRAINING")
                    .severity("MEDIUM")
                    .title("Tần suất tập luyện cao")
                    .message("Bạn đã tập khá nhiều ngày trong tuần.")
                    .action("Hãy bảo đảm ngủ, dinh dưỡng và phục hồi đầy đủ; tránh tập mọi hiệp đến mức thất bại.")
                    .build());
        }
    }

    private void analyzeWeightAndWaist(WeeklyReportResponse report, List<RecommendationItemResponse> items) {
        Double weightChange = report.getWeightChange();
        Double waistChange = report.getWaistChange();

        if (weightChange == null && waistChange == null) {
            items.add(RecommendationItemResponse.builder()
                    .type("BODY")
                    .severity("MEDIUM")
                    .title("Thiếu dữ liệu cơ thể")
                    .message("Chưa có đủ dữ liệu cân nặng hoặc vòng eo trong tuần.")
                    .action("Ghi cân nặng và vòng eo ít nhất 2 lần mỗi tuần để đánh giá tiến độ.")
                    .build());
            return;
        }

        if (weightChange != null && waistChange != null) {
            if (weightChange > 0.7 && waistChange > 1.0) {
                items.add(RecommendationItemResponse.builder()
                        .type("BODY")
                        .severity("HIGH")
                        .title("Tốc độ tăng cân có thể quá nhanh")
                        .message("Cân nặng và vòng eo đều tăng nhanh.")
                        .action("Giảm 150–250 kcal mỗi ngày hoặc tăng số bước đi hằng ngày.")
                        .build());
            } else if (weightChange > 0 && waistChange <= 0.5) {
                items.add(RecommendationItemResponse.builder()
                        .type("BODY")
                        .severity("LOW")
                        .title("Tăng cơ đang được kiểm soát")
                        .message("Cân nặng tăng trong khi vòng eo vẫn ổn định.")
                        .action("Duy trì mức năng lượng hiện tại và tiếp tục tăng tiến trong tập luyện.")
                        .build());
            } else if (weightChange < -0.7) {
                items.add(RecommendationItemResponse.builder()
                        .type("BODY")
                        .severity("MEDIUM")
                        .title("Cân nặng giảm nhanh")
                        .message("Giảm cân quá nhanh có thể ảnh hưởng đến phục hồi và sức mạnh.")
                        .action("Tăng nhẹ năng lượng hoặc bảo đảm bổ sung đủ protein và ngủ đủ.")
                        .build());
            }
        }
    }

    private String buildSummary(WeeklyReportResponse report) {
        if (!Boolean.TRUE.equals(report.getNutritionDataSufficient())) {
            return "Chưa đủ dữ liệu để đánh giá lượng ăn. Bạn mới xác nhận "
                    + safeInt(report.getCompleteNutritionDays()) + "/"
                    + safeInt(report.getPeriodDays())
                    + " ngày ghi đầy đủ; các ngày ghi thiếu đã được loại khỏi khuyến nghị.";
        }
        return "Trong khoảng báo cáo, trung bình mỗi ngày bạn nạp "
                + round(safe(report.getAverageCalories())) + " kcal và "
                + round(safe(report.getAverageProtein())) + " g protein; luyện tập "
                + safeInt(report.getWorkoutDays()) + " ngày; thay đổi cân nặng: "
                + formatWeightChange(report.getWeightChange()) + ".";
    }

    private String formatWeightChange(Double value) {
        if (value == null) {
            return "chưa có dữ liệu";
        }

        return round(value) + " kg";
    }

    private double safe(Double value) {
        return value == null ? 0.0 : value;
    }

    private int safeInt(Integer value) {
        return value == null ? 0 : value;
    }

    private double round(double value) {
        return Math.round(value * 10.0) / 10.0;
    }
}
