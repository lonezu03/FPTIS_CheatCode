# Mở rộng tính năng web và app

Ngày: 2026-10-27. Trạng thái: đã được người dùng duyệt, đã triển khai source.
Người dùng yêu cầu thực hiện cả 10 ý tưởng trên backend/web/Flutter.
Kết quả, giới hạn và checklist phát hành: docs/FEATURE_EXPANSION_RELEASE.md.

## Phạm vi và thứ tự

| Đợt | Tính năng | Tích hợp |
|---|---|---|
| 1 | Chu kỳ tập 4–12 tuần; Superset/Circuit; lịch tập liên kết giáo án | WorkoutPlan, live workout/history và calendar trên web/Flutter |
| 2 | Thực đơn tuần; danh sách mua thực phẩm | NutritionCollection hiện có, diary và trang/app nutrition |
| 3 | Mục tiêu theo giai đoạn; thói quen; giấc ngủ/phục hồi | Body measurements, workout intelligence, Todo/Health |
| 4 | Mục tiêu tiết kiệm | Finance, không thay đổi ledger/báo cáo hiện có |
| 5 | Chia sẻ và sao chép giáo án/thực đơn | Bản mẫu chọn chia sẻ, bản sao thuộc người nhận |
| 6 | Kiểm tra tích hợp đủ 10 tính năng | Phân quyền, menu, responsive, API contracts, migration/tests |

Tất cả có backend thật, giao diện web và Flutter, DTO/API thống nhất. Không sửa
nghiệp vụ đặt cơm, không tự deploy/động dữ liệu production, không tự build APK
khi tính năng chưa hoàn tất kiểm tra. Giữ nguyên diff sửa menu đang có.

## Các mặc định đề nghị duyệt

1. Chu kỳ có tuần tập/giảm tải, người dùng đặt chỉ tiêu từng tuần. Không tự tăng
   tạ hoặc thay kế hoạch mà chưa xác nhận. Superset/Circuit lưu nhóm/thứ tự/vòng,
   phân biệt nghỉ giữa bài và nghỉ giữa vòng; lịch sử cũ vẫn giữ nguyên.
2. Lịch tập lưu snapshot mục tiêu và nhãn giáo án. Mỗi lần tập trong lịch có định
   danh riêng; hoàn thành một lần không hoàn thành cả chuỗi lặp. Chỉ khi lưu buổi
   tập thực tế mới đánh hoàn thành, chống ghi trùng. Thay đổi giáo án phải rõ ràng
   để không âm thầm đổi các buổi đã lên lịch hoặc lịch sử.
3. Thực đơn dự kiến tách khỏi nhật ký đã ăn. Chỉ thao tác xác nhận đã ăn mới ghi
   diary một lần; không tự xác nhận ngày dinh dưỡng đầy đủ. Danh sách mua gộp theo
   food ID/đơn vị tương thích, không tự suy nguyên liệu của món chế biến sẵn hoặc
   đổi gram sang ml. Tạo lại danh sách không làm mất mục tự thêm/đã mua âm thầm.
4. Mục tiêu có baseline/đích/mốc thời gian và minh chứng nếu có; thiếu số liệu là
   chưa biết, không phải 0. Không tự sửa mục tiêu calo của hồ sơ người dùng.
5. Thói quen độc lập với Todo, dùng quyền Todo hiện có. Check-in theo ngày Việt
   Nam, không sinh Todo quá hạn hay carry-over. Lịch sử hoàn thành phải giữ lại.
6. Giấc ngủ/phục hồi nhập tay trước, hỗ trợ qua nửa đêm, kiểm tra khoảng trùng và
   giá trị thiếu. Chưa nhận đồng bộ sleep từ Health Connect. Không chẩn đoán bệnh.
7. Tiết kiệm là sổ ghi nhận tiến độ ADD/RELEASE riêng, được ghi rõ không khóa tiền
   và không tự trừ ví/tạo chi tiêu. Chuyển tiền thật giữa ví vẫn dùng TRANSFER và
   xác nhận riêng. Không tự lấy chi tiêu SAVING cũ để cộng vào mục tiêu mới.
8. Chia sẻ chỉ cho tài khoản được chọn, chủ sở hữu chủ động chọn bản mẫu; không
   công khai link ở đợt đầu. Người nhận xem trước rồi sao chép về sở hữu riêng.
   Thu hồi chặn truy cập/sao chép tiếp, không xóa bản sao đã nhận. Không chia sẻ
   nhật ký thực tế, dữ liệu sức khỏe/tài chính hoặc dữ liệu cá nhân khác kèm theo.

## Phân quyền đề xuất

- Chu kỳ/nhóm bài/chia sẻ giáo án: fitnessEnabled.
- Thực đơn/mua thực phẩm/chia sẻ thực đơn: healthEnabled, theo backend nutrition.
- Mục tiêu cơ thể/phục hồi/giấc ngủ: healthEnabled; mục tiêu thành tích tập: fitnessEnabled.
- Thói quen: todoEnabled. Tiết kiệm: financeEnabled.
- Liên kết vào lịch cần scheduleEnabled và quyền của tính năng nguồn.
- ADMIN không được đọc dữ liệu riêng của chủ sở hữu khác nhờ bypass module.
- Đặt màn con trong module sẵn có, không mở rộng 13 menu key trong đợt đầu để
  không làm hỏng app cũ. Ẩn menu không thay thế kiểm tra quyền API.

## Rủi ro đã xác minh từ source

- WorkoutPlanService cập nhật bằng cách xóa/tạo lại ngày tập: không hard-FK lịch
  vào plan-day ID không ổn định. WorkoutSession chưa có nguồn lịch/chu kỳ.
- NutritionCollection đã có SAVED_MEAL/RECIPE: tái sử dụng, không làm lại công thức.
- Schedule đang mở rộng lịch lặp ảo: trạng thái hoàn thành phải theo occurrence.
- Finance tính số dư từ opening balance/giao dịch POSTED: không ghi tiết kiệm
  thành EXPENSE hay giả lập số dư bổ sung. Đề nghị không làm hard-reservation ví.
- Health Connect chưa hỗ trợ sleep: không gán nhãn đồng bộ thiết bị khi chỉ nhập tay.

## Database và nghiệm thu

Migration mới, dự kiến V36–V41 theo nhóm, không sửa V1–V35 đã có. Bảng sở hữu,
index user/date/status; version cho aggregate chỉnh sửa; khóa/unique operation ID
cho xác nhận ăn/tập/sao chép/ghi nhận tiết kiệm. Không chuyển toàn bộ UUID sang ID số.

Test: cô lập chủ sở hữu, quyền bị thu hồi, tài khoản admin, dữ liệu thiếu,
chỉnh/xóa bản mẫu, qua ngày/tuần, lịch lặp, thao tác lặp sau timeout, không tăng
lịch sử khi chỉ lên kế hoạch, không đổi balance/report khi ghi nhận tiết kiệm.
Chạy JDK21 Maven, web lint/tests/build, Flutter analyze/tests và kiểm tra màn nhỏ.
PostgreSQL staging/Flyway và kiểm tra thiết bị thực tế trước phát hành. Mỗi đợt
phải có báo cáo phần thực sự hoàn tất, không coi có endpoint là đã đủ tính năng.
