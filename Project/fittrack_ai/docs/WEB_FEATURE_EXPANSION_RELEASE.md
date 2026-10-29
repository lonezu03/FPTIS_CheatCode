# Hướng dẫn 8 tính năng web mới

Ngày 28/10/2026: backend + web responsive. Ngày 29/10: bổ sung Flutter cho các
tính năng này; trạng thái build và kiểm thử cuối xem đầu CODEX_CONTEXT.md. Không
sửa nghiệp vụ/giao diện đặt cơm, không deploy hoặc truy cập DB thật. Kế hoạch web
được người dùng duyệt: WEB_FEATURE_EXPANSION_PLAN.md.

Trên app, mở các màn mới từ mục **Thêm** theo module và quyền được cấp. Báo cáo
tháng có in/lưu PDF cục bộ. Đồng hồ tập trung chỉ nhắc khi màn hình đang chạy;
lịch sử hiện giới hạn 15 phiên đầu tháng và danh sách chọn việc 50 mục đầu. Cần
kiểm tra thông báo và hộp thoại in trên điện thoại thật. V42–V45 vẫn cần được
kiểm tra PostgreSQL staging và deploy backend trước khi dùng các màn mới.

## Mở chức năng

| Tính năng | Đường dẫn web | Quyền |
|---|---|---|
| Thực phẩm đang có, lô/hạn dùng | `/pantry` | healthEnabled |
| Giá mua và ước tính thực đơn | `/purchase-prices` | healthEnabled + financeEnabled |
| So sánh giai đoạn/giáo án | `/training-comparison` | fitnessEnabled |
| Thay bài khi máy bận | `/workouts` → buổi trực tiếp → Đổi bài tương đương | fitnessEnabled |
| Chi tiêu chung | `/finance/shared` | financeEnabled + tư cách nhóm |
| Bản đồ thói quen | `/habits` → Ghi nhận / lịch sử | todoEnabled |
| Chế độ tập trung | `/focus` | todoEnabled |
| Báo cáo tháng và in/lưu PDF | `/reports/monthly` | quyền riêng từng nội dung được chọn |

Menu hiện các màn con theo quyền. API vẫn kiểm quyền thật; ADMIN không đọc kho,
giá, báo cáo hoặc nhóm của tài khoản khác nếu không có tư cách phù hợp.

## 1. Kho thực phẩm cá nhân

- Nhập lô từ catalog đã duyệt, lượng/đơn vị, vị trí cất, hạn dùng và ghi chú.
  Có lưu trữ/khôi phục, lịch sử và các thao tác nhập thêm/đã dùng/hủy/đối soát.
- Đối soát là đặt tồn thực tế (có thể 0), bắt buộc lý do. Lịch sử lưu biến động
  có dấu và tồn sau thao tác; không cho lượng âm. Version và operationId bảo vệ
  ghi đè/ghi trùng sau timeout. Không tự đổi nhật ký ăn hay số dư ví.
- Gợi ý đối chiếu bữa/công thức đã lưu, không tự suy nguyên liệu món hoàn chỉnh.
  Không tính lô hết hạn. Thiếu quy đổi được ghi rõ, không suy gram ↔ ml.
- Nhắc hạn dùng chạy 08:00 giờ VN, một lần cho lô/ngày hết hạn khi còn trong
  khoảng 3 ngày trước hạn. Chỉ lô hoạt động còn tồn, chủ có quyền/đang hoạt động;
  email theo opt-in. Backend phải đang chạy vào thời điểm lịch; Render ngủ hoặc
  mail chưa cấu hình thì không thể cam kết nhận nhắc đúng giờ. Hạn dùng không
  phải bảo đảm an toàn thực phẩm, luôn tự kiểm tra trước khi sử dụng.

## 2. Giá mua và chi phí tuần

- Ghi giá VND, lượng mua, đơn vị, nơi/ngày mua; sửa/lưu trữ và lọc lịch sử theo
  thực phẩm. Đây không phải hóa đơn hoặc giao dịch chi tiêu và không tự nhập kho.
- Chọn thứ Hai và mốc ngày để tính dự kiến cả tuần từ thực đơn đã lập. Chọn giá
  tương thích gần nhất tại/trước mốc, không dùng giá tương lai hoặc đã lưu trữ.
- Tổng hiển thị là phần đã có giá, kèm tỷ lệ bao phủ và từng dòng chưa biết.
  Thiếu giá không phải bằng 0. Không trừ tồn đang có hoặc tự chuyển tiền.

## 3. So sánh và thay bài tập

- Chọn hai khoảng cùng số ngày, tối đa 366 ngày mỗi khoảng. Có số buổi/ngày tập,
  hiệp chính, volume và chỉ số từng bài. Không tính WARMUP/chưa hoàn tất; e1RM
  chỉ 1–30 reps. So sánh giáo án chỉ dựa buổi có liên kết lịch và thực tế,
  không tự gán buổi tập tự do cũ vào giáo án. Không kết luận hiệu quả y khoa.
- Bài tương đương dùng bộ lọc cùng nhóm cơ, active/approved, preference và dụng
  cụ. Chọn thay cần xác nhận; hiệp đã xong giữ nguyên, hiệp chưa làm sang phần
  bài mới với tạ 0 để người dùng xem lại, không mang tạ máy sang tạ đơn tự động.
- Lưu originalExerciseId và replacementKind: ALTERNATIVE cho gợi ý tương đương,
  MANUAL cho lựa chọn chủ động từ thư viện (có thể khác nhóm cơ). Đây là dấu vết
  thay đổi, không chứng nhận bài manual tương đương. Đổi nhiều lần vẫn giữ bài
  ban đầu, không sửa giáo án gốc hoặc tự viết lại lịch sử tập cũ.

## 4. Chi tiêu chung

- Tạo nhóm, mời email tài khoản đã đăng ký/có quyền, người nhận chấp nhận trước
  khi xem. Chính sách hiển thị trước khi chấp nhận: người đã chấp nhận được xem
  toàn bộ lịch sử/công nợ nhóm cả sau khi rời để đối soát, nhưng không ghi chi mới.
- VND nguyên đồng, một người trả, chia đều (phần dư phân theo thứ tự ID ổn định)
  hoặc nhập phần từng người. Xem trước server trước lưu; tổng phải khớp chính xác.
- Người tạo sửa/hủy khoản của mình; chủ nhóm chỉ hủy khoản người khác có lý do,
  không âm thầm chỉnh sửa. Có audit, version và operationId chống ghi trùng.
- Trả nợ theo số dư ròng; một trong hai bên đề nghị, bên còn lại xác nhận mới
  giảm nợ. Đề nghị chờ không thay nợ, xác nhận kiểm tra lại để không trả vượt.
  Khoản cũ trước một đối soát đã xác nhận bị khóa sửa/hủy để giữ lịch sử đã chốt.
- Không chuyển tiền thật, không tự tạo giao dịch ví và không liên quan quỹ cơm.
  Audit API không đưa email người được mời cho thành viên không phải chủ nhóm.

## 5. Bản đồ thói quen

- Lịch màu DONE/SKIPPED/MISSED/PENDING/REST/UNKNOWN; chuỗi cuối khoảng, dài nhất
  và tỷ lệ trong khoảng chọn. Ngày nghỉ không ngắt chuỗi, hôm nay chưa xong chưa
  tính thất bại. SKIPPED không phải DONE. Không tự sinh Todo quá hạn.
- Sửa lịch có hiệu lực ngày mai (hoặc ngày bắt đầu nếu còn ở tương lai), không
  thay lịch quá khứ. Lịch cũ trước V44 chưa có lịch sử hiệu lực thì UNKNOWN,
  không đưa vào mẫu số/chuỗi như thể đã biết. Lưu trữ chặn tính sau ngày lưu trữ;
  muốn bắt đầu lại tạo thói quen mới, không viết lại dữ liệu cũ.

## 6. Đồng hồ tập trung

- Chọn công việc hoặc tên riêng, chế độ tập trung/nghỉ và thời lượng. Một người
  chỉ có một phiên chạy/tạm dừng. Tải lại/đổi thiết bị lấy trạng thái server;
  tạm dừng/tiếp tục/kết thúc/hủy có khóa, version và idempotency.
- Không tự đánh DONE công việc, không đổi ngày hạn hoặc estimatedMinutes. Xóa
  công việc không xóa dấu vết phiên; thời gian là đồng hồ, không chứng minh đã
  thực sự làm việc. Tối đa ghi nhận 8 giờ; phiên dài cần kết thúc/hủy để xem lại.
- Thông báo xin quyền trên trang, best-effort lúc đang mở. Không hứa chuông khi
  trình duyệt đóng/điện thoại đình chỉ. Trình duyệt không cho tạo notification
  sẽ nhận nhắc trong web, không làm trang crash.

## 7. Báo cáo tháng

- Chọn tháng, chọn các nội dung được phép, nhấn xem trước rồi In/lưu PDF qua
  trình duyệt. Không tự gửi email, không gọi AI/dịch vụ xuất file bên ngoài.
- Chỉ truy vấn nội dung đã chọn sau khi xác minh đủ quyền. Không xuất Journal
  hoặc công nợ nhóm; ADMIN vẫn chỉ dữ liệu cá nhân của mình.
- Dinh dưỡng COMPLETE/FASTING, kèm độ bao phủ. Thiếu ngày/chỉ số là chưa biết,
  không phải đã ăn 0. Tập chỉ working sets hoàn tất. Focus tính các phiên FOCUS
  đã kết thúc trong tháng, không tính BREAK/CANCELLED hoặc phiên đang chạy.
- Finance chỉ POSTED thu/chi, loại VOID/TRANSFER/số dư đầu kỳ, tách từng tiền tệ.
  Đã chặn đổi tiền tệ ví có lịch sử (kể cả giao dịch VOID/chuyển đến) để tránh
  đổi nhãn báo cáo cũ. Không thể phục hồi tiền tệ từng giao dịch nếu đã đổi nhãn
  trước bản sửa này; khi nghi lệch phải đối soát dữ liệu gốc.

## Migration và kiểm tra phát hành

V42: pantry/stock ledger/purchase prices. V43: nhóm/thành viên/chi/đối soát/audit.
V44: nguồn bài thay và lịch sử hiệu lực thói quen. V45: focus sessions/operations.
Không chỉnh V1–V41; không đổi ID toàn hệ thống. Sau kiểm tra staging, deploy
backend trước web. Trạng thái chạy test cuối ghi ở đầu CODEX_CONTEXT.md.

```powershell
cd backend
.\mvnw.cmd test
# Dùng JDK 21; bật Docker để hai test PostgreSQL không bị skip.

cd ..\frontend\fittrack-frontend
npm run lint
node .\node_modules\vitest\vitest.mjs run --maxWorkers=1 --no-file-parallelism
npm run build
node .\node_modules\@playwright\test\cli.js test --config playwright.expansion.config.ts
```

Browser tests dùng API giả lập và bản build production tại localhost, không ghi
production. Phải kiểm PostgreSQL nâng từ V41 có dữ liệu + Hibernate validate,
mail/nhắc hạn thật và thao tác trên điện thoại trước khi phát hành chính thức.
Docker engine chưa hoạt động trên máy này, vì vậy H2/build không chứng minh
Flyway V42–45 đã chạy được trên Aiven.
