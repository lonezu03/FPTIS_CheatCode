# Mở rộng FitTrack: hướng dẫn và kiểm tra phát hành

Ngày 27/10/2026. Source backend, web và Flutter đã được bổ sung cho 10 nhóm
tính năng đã duyệt. Không tự deploy, không build APK trong đợt này, không sửa
nghiệp vụ/giao diện đặt cơm và không truy cập DB production.

## Vào đâu để dùng

| Chức năng | Web | App |
|---|---|---|
| Chu kỳ 4–12 tuần | Giáo án → Chu kỳ và lịch tập | Giáo án → Chu kỳ và lịch tập |
| Superset/Circuit | Thiết lập nhóm trong giáo án/buổi tập | Giáo án/buổi tập → nhóm bài |
| Lịch từ giáo án | Giáo án → lên lịch; Thời khóa biểu → buổi tập | Giáo án → lên lịch; Lịch & việc → buổi tập |
| Thực đơn tuần | Thực đơn & danh sách mua | Thêm → Thực đơn & danh sách mua |
| Danh sách mua | Trong màn thực đơn tuần | Trong màn thực đơn tuần |
| Mục tiêu theo giai đoạn | Mục tiêu luyện tập / Mục tiêu sức khỏe | Thêm → các mục tiêu tương ứng |
| Thói quen | Thói quen | Thêm → Thói quen |
| Ngủ/phục hồi | Giấc ngủ & phục hồi | Thêm → Giấc ngủ & phục hồi |
| Tiết kiệm | Mục tiêu tiết kiệm | Thêm → Mục tiêu tiết kiệm |
| Chia sẻ mẫu | Chia sẻ bản mẫu | Thêm → Chia sẻ bản mẫu |

App vẫn sử dụng 13 menu key hiện có; màn con phụ thuộc quyền và trạng thái hiện
của module cha, kể cả ADMIN. Đã thống nhất quyền foods/nutrition theo healthEnabled
ở menu và thanh điều hướng chính. Ẩn menu không thay thế quyền API.

## Các giới hạn có chủ đích

- Chu kỳ: mục tiêu tải/tuần do người dùng nhập và xác nhận, không tự tăng tạ.
  Tiến độ chu kỳ đếm các occurrence có buổi tập thực tế đã lưu.
- Nhóm bài lưu thứ tự/vòng và hai loại nghỉ; có hướng dẫn bài/vòng tiếp theo.
  Người dùng vẫn tự đánh dấu từng hiệp; không tự suy ra đã hoàn thành.
- Lịch tập giữ snapshot ngày giáo án, không lệ thuộc ID ngày có thể bị thay khi
  sửa giáo án. Chỉ lưu buổi thực tế có hiệp chính hoàn tất mới đánh DONE.
  Hủy trình tập không ghi lịch sử; retry cùng occurrence không tạo buổi mới.
- Thực đơn dự kiến có tổng cả tuần độc lập phân trang. Xác nhận đã ăn tạo một
  nhật ký thực tế duy nhất và tính lại từ catalog hiện tại sau cảnh báo; không
  tự xác nhận ngày COMPLETE. Giá trị snapshot kế hoạch không phải intake thật.
- Mua hàng chỉ gộp cùng food ID và cùng đơn vị, không suy mật độ gram/ml hoặc
  nguyên liệu của món nấu sẵn. Tạo lại giữ mục tự thêm/đã mua; mục thay đổi được
  đánh dấu cần đối chiếu. Không tích hợp siêu thị/đặt mua.
- Mục tiêu: baseline, đích, các giai đoạn và ghi nhận số đo/minh chứng nhập tay.
  Không tự xác minh mã buổi tập hay lấy số đo thay người dùng. Thói quen độc lập
  Todo, ghi DONE/SKIPPED theo ngày Việt Nam; không sinh công việc quá hạn.
  Hiện xem lịch sử ngày, chưa có heatmap/streak tổng hợp.
- Phục hồi: nhập tay, hỗ trợ ngủ qua đêm, chống khoảng trùng, đánh giá 1–5 có thể
  bỏ trống. Không phải chẩn đoán và chưa đồng bộ giấc ngủ từ thiết bị.
- Tiết kiệm là tiến độ ảo ADD/RELEASE riêng: KHÔNG khóa tiền, không đổi ví,
  không tạo thu/chi hoặc đổi báo cáo. Giới hạn mỗi số tiền/tổng là 1.000 tỷ;
  số dương, tối đa 2 số lẻ, cùng tiền tệ. Chuyển tiền thật dùng Finance riêng.
- Chia sẻ: chọn một tài khoản qua email và mẫu giáo án/bữa ăn/công thức/tuần ăn.
  Chỉ người gửi/người nhận được xem, không có link công khai. Người nhận có
  quyền module và catalog còn được duyệt mới sao chép được. Mỗi chia sẻ tạo tối
  đa một bản sao; copy tuần cần chọn thứ Hai. Thu hồi/hết hạn ngăn truy cập tiếp,
  không xóa bản sao đã có. Không chia sẻ nhật ký thực tế hoặc ghi chú riêng của
  từng bữa trong tuần. Mô tả giáo án/công thức được chủ động gửi theo bản mẫu.

## API và migration

- `/api/workout-plans/cycles`, `/appointments`: fitness; lịch còn cần schedule.
- `/api/nutrition/planning/meals`, `/copy-week`, `/summary`, `/groceries`: health.
- `/api/workouts/goals`: fitness; `/api/health-management/tracking/**`: health.
- `/api/todos/habits`: todo; `/api/finance/savings`: finance.
- `/api/template-shares`: kiểm quyền theo loại mẫu và cô lập người gửi/nhận.
- V36 nhóm bài/chu kỳ; V37 snapshot lịch tập; V38 thực đơn/mua hàng;
  V39 mục tiêu/thói quen/phục hồi; V40 tiết kiệm ảo; V41 chia sẻ.

Các thay đổi additive. Không sửa V1–V35; không đổi kiểu ID toàn DB. Aggregate
có version; xác nhận tập/ăn/sao chép/tiết kiệm có khóa/idempotency. Phase-only
goal edits cũng tăng parent version. Lỗi ResponseStatusException 4xx được trả
đúng status thay vì bị generic handler chuyển thành 500; 5xx không lộ chi tiết.

## Trước khi phát hành

1. Chạy JDK21 Maven tests. Hai bài Testcontainers cần Docker: Flyway từ đầu tới
   V41 và Spring context với ddl-auto=validate. Kiểm tra thêm bản staging nâng
   từ V35 có dữ liệu trước khi chạy production. Không bỏ validate để né lỗi.
2. Chạy web lint/test/build, Flutter analyze/test. Chỉ build APK khi được yêu cầu
   và backend đã tương thích. Không dùng APK cũ để kiểm tra các màn mới.
3. Smoke bằng hai USER và một ADMIN: quyền fitness-only/health-only/todo-only,
   thu hồi quyền trong lúc mở màn, ẩn module app áp dụng cả admin. Admin không
   được đọc mục tiêu/tiết kiệm/chia sẻ của người khác nếu không là người nhận.
4. Tập: lên lịch lặp, sửa/xóa giáo án gốc, mở snapshot, hủy/hoàn thành/retry sau
   timeout; warmup-only và tất cả set chưa hoàn tất không đánh DONE.
5. Ăn: tuần >30 bữa, copy/retry, tạo lại danh sách mua sau khi đánh đã mua,
   xác nhận đã ăn hai lần, catalog đã lưu trữ, đơn vị gram/ml không tương thích.
6. Mục tiêu sửa riêng giai đoạn từ hai tab; ngủ qua đêm/trùng giờ; thói quen
   lệch ngày VN; tiết kiệm retry ADD/RELEASE và kiểm ví/báo cáo không đổi.
7. Chia sẻ xem trước/copy/thu hồi/hết hạn, recipient bị khóa/thu hồi quyền,
   chủ sở hữu sửa/xóa bản gốc; kiểm bản sao không bị xóa theo nguồn.
8. Kiểm tra Android thật ở màn hẹp, bàn phím, Back, mạng chậm và token refresh.
   Widget/mock tests không thay thế kiểm tra điện thoại hoặc staging.

Kết quả thực tế của lần kiểm tra cuối được ghi ở đầu docs/CODEX_CONTEXT.md.
