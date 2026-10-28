# Kế hoạch 8 tính năng web tiếp theo

Ngày: 2026-10-28. Trạng thái: người dùng đã duyệt, đã triển khai backend/web.
Phạm vi, giới hạn và nghiệm thu thực tế: docs/WEB_FEATURE_EXPANSION_RELEASE.md.

## Phạm vi

Backend và web responsive; chưa mở rộng Flutter, không build APK/deploy/push,
không kết nối production hoặc thay đổi module đặt cơm. Giữ API cũ tương thích.
Baseline hiện tại commit 5284d330 đã chứa 10 nhóm mở rộng trước, migrations V36–41.
CODEX_CONTEXT cũ chưa phản ánh đúng baseline này; không triển khai lại 10 nhóm đó.

## Tính năng và quy tắc đã duyệt

1. Kho thực phẩm cá nhân: lô hàng, thực phẩm tham chiếu catalog, vị trí cất,
   lượng tồn, hạn dùng tùy chọn; lịch sử nhập/dùng/hủy/đối soát có ghi chú.
   Không cho tồn âm; mỗi thao tác có operationId, khóa lô và version chống ghi
   đè. Chỉ quy đổi SERVING/GRAM/ML khi có hệ số hợp lệ; tuyệt đối không suy g↔ml.
   Nhắc sắp hết hạn mặc định trước 3 ngày bằng notification dùng chung có dedup;
   email tuân theo opt-in. Gợi ý tận dụng bằng đối chiếu food ID/công thức đã lưu,
   không giả định món chế biến sẵn có đủ nguyên liệu. Không tự trừ tồn khi ghi ăn:
   người dùng phải xác nhận lượng/lô xuất, độc lập Nutrition diary.
2. So sánh tập: hai khoảng ngày cùng độ dài hoặc hai giáo án, buổi/set chính đã
   hoàn thành, volume, PR/e1RM theo quy tắc cũ và độ đều đặn. So sánh giáo án chỉ
   dùng occurrence có liên kết thật ở training_appointments; không gán lịch sử
   cũ theo tên/ngày. Hiển thị số buổi đủ liên kết và cảnh báo thiếu dữ liệu, không
   kết luận một giáo án gây tăng cơ hoặc hiệu quả y khoa.
3. Thay bài khi máy bận: tái sử dụng alternatives API hiện có. Bổ sung lọc dụng
   cụ và xác nhận; chỉ đổi các hiệp chưa làm, giữ bài và số liệu của hiệp đã
   hoàn tất. Chuyển sang tạ/dụng cụ khác không tự mang mức tạ cũ sang: xem lại
   tải; giữ provenance bài dự kiến/bài thực tế. Không sửa giáo án gốc hoặc buổi
   lịch sử. Chỉ đề xuất bài active/approved cùng nhóm cơ, không EXCLUDED.
4. Giá thực phẩm: nhập giá mua, số lượng/đơn vị, ngày và nơi mua; tính giá đơn vị
   và diễn biến giá. Đợt đầu VND; không kết nối cửa hàng/bank hoặc tự tạo EXPENSE.
   Ước tính chi phí tuần ăn từ giá mua phù hợp gần nhất, có mốc ngày/nguồn và tỷ
   lệ bao phủ; thiếu giá/không quy đổi được là chưa biết, không phải miễn phí.
5. Chi tiêu chung: nhóm riêng, mời tài khoản qua email và chỉ chia sẻ sau khi
   họ chấp nhận. Thành viên chỉ thấy dữ liệu nhóm của mình; ADMIN không đọc
   nhóm bất kỳ. VND, một người trả cho một khoản, chia đều hoặc nhập số tiền
   từng người (tổng khớp tuyệt đối; chia dư đồng theo thứ tự ổn định được xem
   trước). Sửa/hủy có version và audit; không xóa lịch sử. Ghi trả nợ cần bên
   kia xác nhận trước khi giảm công nợ, retry idempotent. Chủ nhóm quản lý lời
   mời/thành viên; người tạo khoản được sửa/hủy khoản của mình, chủ nhóm có thể
   hủy có lý do và audit nhưng không âm thầm sửa khoản người khác. Thành viên
   rời nhóm vẫn giữ lịch sử và công nợ. Không chuyển tiền thật,
   không tự tác động ví cá nhân/Finance và hoàn toàn độc lập Lunch ledger.
6. Bản đồ thói quen: dùng HABIT và checkins hiện có, lịch màu tối đa 366 ngày,
   tỷ lệ/chuỗi hiện tại/dài nhất. Chỉ các ngày thuộc lịch thực hiện mới tính;
   ngày nghỉ không làm đứt chuỗi, SKIPPED/ngày phải làm bị thiếu trong quá khứ
   làm đứt, hôm nay chưa xong không tính thất bại trước khi hết ngày VN.
   Không tạo Todo hay tính ngày trước ngày bắt đầu. Cần lưu hiệu lực lịch ngày
   trong tuần để sửa lịch không viết lại kết quả quá khứ. Với dữ liệu trước khi
   có lịch sử hiệu lực, phải ghi rõ lịch cũ chưa xác minh, không tuyên bố chuỗi
   lịch sử tuyệt đối chính xác chỉ từ cấu hình weekdays hiện tại.
7. Tập trung: phiên làm/nghỉ tùy chỉnh, liên kết Todo hoặc đặt tên riêng, pause/
   resume/finish/cancel; trạng thái lưu server để tải lại tiếp tục được. Mỗi
   người tối đa một phiên chạy, version và operationId chống thao tác trùng từ
   hai tab. Thời gian là elapsed của đồng hồ, không chứng minh người dùng thực
   sự tập trung. Không tự DONE Todo, không đổi deadline/duration dự kiến. Nhắc
   trên web có xin quyền; không hứa timer/thông báo nền hoạt động khi trình duyệt
   bị đóng/đình chỉ. Phiên dài quá 8 giờ cần chốt/xem lại thay vì tự ghi vô hạn.
8. Báo cáo tháng: chọn tập luyện/dinh dưỡng/thói quen/tài chính theo quyền hiện
   tại; chỉ dữ liệu chính chủ. Dinh dưỡng chỉ dùng COMPLETE/FASTING để tính
   trung bình; hiển thị độ bao phủ, không coi ngày thiếu là 0. Tiền đúng POSTED,
   bỏ VOID, không tính transfer/opening balance thành thu nhập. Không xuất nội
   dung Journal, chia sẻ nhóm hoặc dữ liệu nhạy cảm khác mặc định. Xem trước
   và in/lưu PDF qua trình duyệt, không tự gửi email hoặc upload dịch vụ khác.

## Phân quyền và tích hợp

- Pantry: healthEnabled; luyện tập: fitnessEnabled; giá mua và ước tính chi phí
  trong thực đơn cần đồng thời healthEnabled + financeEnabled.
- Chi tiêu chung: financeEnabled và membership/consent ở service.
- Heatmap và focus: todoEnabled; báo cáo từng khối kiểm quyền nguồn trên backend,
  không bắt fitness-only user có health chỉ để đọc báo cáo tập.
- Giữ các màn con trong menu sẵn có; không cấp quyền nhờ hiển thị menu.
- Web dùng API client chung, loading/mutation guard, giữ form khi lỗi, không mock
  dữ liệu lúc thiếu API. API tiền dùng BigDecimal và giới hạn an toàn client.

## Thiết kế source/API dự kiến

- Packages mới pantry, purchaseprices, finance/shared, focus; mở rộng workout
  intelligence, personaltracking và report với DTO/service/repository rõ ràng.
- `/api/nutrition/pantry/**`, `/api/nutrition/purchase-prices/**` (giá cần cả
  health + finance), `/api/workouts/comparison`, alternatives hiện có,
  `/api/finance/shared/**`, `/api/todos/habits/{id}/calendar`,
  `/api/todos/focus/**`, `/api/personal-reports/monthly` (quyền từng khối).
  Đây là hợp đồng đề xuất, chốt DTO chi tiết trước khi giao worker thực thi.
- Flyway mới từ V42: batches/stock ledger/purchase prices; tiếp theo shared
  expenses/invitations/splits/settlements; focus/substitution provenance và
  habit schedule effective-history. Không sửa V1–V41 đã nằm trong baseline.
- Web: các trang pantry, giá mua, so sánh tập, chi tiêu chung, focus, báo cáo;
  mở rộng PersonalTrackingPage cho heatmap và WorkoutPage cho thay bài an toàn;
  điều hướng AppRoutes/AppLayout dùng quyền hiện có.

## Thứ tự và nghiệm thu

1. Chốt quy tắc và DTO, phân ownership để không trùng file.
2. Luyện tập + habits/focus; pantry/giá mua; chi tiêu chung; cuối cùng báo cáo.
3. Mỗi nhóm có test owner/ADMIN/thu hồi quyền, concurrency/stale version/retry,
   ngày VN và dữ liệu thiếu. Stock không âm; chia tiền đúng đồng; sửa lịch habit
   không đổi lịch sử; thay bài không chuyển set đã hoàn tất.
4. Chạy Maven JDK21, web lint/test/build, responsive browser tests và review
   độc lập QA/code. Baseline mobile không đổi, không dùng APK để kiểm web mới.
5. PostgreSQL staging: nâng từ V41 có dữ liệu, Flyway và Hibernate validate.
   Docker hiện chưa được xác nhận hoạt động; không suy thành công từ H2.
6. Cập nhật CODEX_CONTEXT và báo rõ phần hoàn tất, giới hạn, manual smoke và
   thứ tự backend-first deployment. Không tuyên bố hoàn tất chỉ vì có endpoint.
