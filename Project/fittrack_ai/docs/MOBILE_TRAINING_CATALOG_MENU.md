# Cập nhật app: luyện tập, dinh dưỡng và menu toàn cục

## Các màn mới

Trong **Thêm**, tài khoản có quyền luyện tập tìm thấy **Giáo án**, **Kho bài tập**,
**Nhật ký ăn uống** và **Kho thực phẩm**, nếu admin chưa ẩn các module đó.
Thứ tự thanh điều hướng và danh sách trong Thêm lấy từ cùng cấu hình. Thanh
điều hướng chỉ giữ tối đa bốn module và mục Thêm để không tràn trên điện thoại.

- Giáo án: tạo/sửa/xóa, nhân bản, thêm/nhân bản/sắp xếp ngày và bài tập; chọn
  nhiều bài trong kho, đặt số hiệp/lần lặp/mức tạ/RIR/thời gian nghỉ/khoảng reps
  và ghi chú. Bản nháp lưu bằng nút rõ ràng, không phải tự động lưu mọi phím gõ.
- Bắt đầu một ngày giáo án mở buổi tập chưa lưu, chưa hoàn thành các hiệp.
  Chỉ nút hoàn thành mới ghi lịch sử. Buổi tập cũ có thể sửa toàn bộ hiệp;
  giữ nguyên ID bài tập lịch sử và thời gian nghỉ riêng từng hiệp.
- Lịch sử buổi tập phân trang, lọc thời gian/bài tập. Volume chỉ tính hiệp chính
  đã hoàn thành, không tính khởi động; tổng trang hiện tại được ghi rõ.
- Kho bài tập: tìm kiếm có phân trang, lọc nhóm cơ/dụng cụ, ảnh và mô tả.
  Kho thực phẩm: khẩu phần, nguồn, độ đầy đủ dữ liệu và các vi chất, không coi
  thông tin chưa biết là số 0. User gửi đề xuất và theo dõi mục đã gửi;
  admin mới được sửa/lưu trữ/khôi phục dữ liệu dùng chung.
- Nhật ký dinh dưỡng tìm trên server theo từng trang, giữ món đã chọn khi đổi
  từ khóa/trang, xem chi tiết snapshot món cũ, sửa hoặc sao chép bữa để tính lại
  theo kho hiện tại. Không tự đổi gram sang ml. Ảnh ước tính gram của đồ uống
  theo ml được đưa về 1 khẩu phần kèm hướng dẫn kiểm tra trước khi lưu.

Nhấn lưu nháp trong giáo án/buổi tập để lưu riêng cho tài khoản trên thiết bị,
hết hạn sau 7 ngày. Phải chủ động khôi phục; đăng xuất xóa nháp của tài khoản.
Không lưu ảnh lớn trong nháp. Nháp không đồng bộ giữa các thiết bị.

## Import trên app

ADMIN vào **Kho bài tập / Kho thực phẩm → Nhập / xuất**. Có thể chọn CSV/XLSX
bằng trình chọn tệp hệ thống hoặc dán bảng TSV; tải mẫu, xuất kho có ID và lưu
dòng lỗi bằng trình lưu tệp. Không cần cấp quyền đọc toàn bộ bộ nhớ điện thoại.

Luồng bắt buộc: xem trước → kiểm tra dòng lỗi/trùng và trước/sau → chọn thao tác
→ tích xác nhận → xác nhận cuối. Upload bị hết access token được làm mới phiên
và tạo lại multipart stream, vẫn nằm trong cùng thao tác theo dõi/chống gửi trùng.
Quy tắc dữ liệu, ô trống/xóa trường, giới hạn và hạn chế xem
[CATALOG_IMPORT.md](CATALOG_IMPORT.md).

## Admin sắp xếp và ẩn/hiện module

Mở **Thêm → Sắp xếp menu app**:

1. Kéo biểu tượng tay nắm để đổi thứ tự.
2. Bật/tắt từng module.
3. Nhấn **Lưu cấu hình toàn bộ app** và xác nhận áp dụng.

Cấu hình áp dụng cho tất cả tài khoản, **kể cả ADMIN**. Module hiển thị khi cả
cấu hình toàn cục bật và tài khoản có quyền tương ứng. Ẩn menu không phải thu hồi
quyền backend: muốn cấm thao tác API phải sửa phân quyền trong Quản trị.
Nhật ký ăn uống có công tắc riêng; tắt cũng ẩn tab nhật ký ăn trong Luyện tập.

Thêm, Thông báo, Cá nhân và đường vào Quản trị/cấu hình menu của ADMIN không nằm
trong danh sách ẩn, để không tự khóa mất nơi mở lại module.

Cấu hình được tải khi mở app, khi app quay lại foreground hoặc kéo làm mới ở
Thêm; không phải cập nhật push tức thời. Lần đầu không tải được cấu hình sẽ chỉ
giữ các lối vào an toàn và nút thử lại, không tự bật tất cả module. Nếu đã tải
thành công, mất mạng giữ cấu hình gần nhất trong bộ nhớ của phiên hiện tại.
Hai admin sửa đồng thời: người dùng bản cũ nhận 409, phải tải lại và kiểm tra
trước khi lưu, không ghi đè âm thầm. Bản đọc cũ không ghi đè kết quả vừa lưu.

API:

- `GET /api/mobile-menu`: tài khoản đã đăng nhập, trả `version` và danh sách
  `modules: [{key, visible}]`; thứ tự mảng là thứ tự menu.
- `PUT /api/admin/mobile-menu`: chỉ ADMIN, gửi lại `version` và toàn bộ 13 module.
  Thiếu/trùng/không đúng key bị từ chối. Lưu phiên bản, thời gian và người sửa gần nhất.

## Trước khi phát hành

Triển khai backend tương thích trước, bao gồm Flyway V32–V35. V35 tạo cấu hình
menu singleton mặc định; mặc định menu bật không thay đổi quyền tài khoản
(user mới vẫn không có quyền Đặt cơm). Kiểm tra migration trên PostgreSQL staging
và sao lưu trước production. Đợt này không đổi nghiệp vụ đặt cơm, URL hay secret.

Sau đó build/cài APK mới theo `mobile/fittrack_mobile/tool/build_android.ps1`.
Không dùng bản app mới với backend cũ thiếu API menu. Chưa có xác nhận thực tế
trên thiết bị cho chọn/lưu file Android/iOS; widget tests không thay thế bước đó.

Smoke test với ADMIN và USER:

1. User không có fitness không thấy các kho/giáo án/dinh dưỡng, không có import.
2. Admin nhập thử 1–2 dòng, hủy xác nhận: kho không thay đổi. Xác nhận rồi kiểm tra
   ID, sửa theo ID và ô trống giữ dữ liệu cũ. Thử upload khi phiên access hết hạn.
3. Tạo giáo án, bắt đầu rồi hủy: lịch sử không tăng. Hoàn thành, sửa buổi tập;
   kiểm tra thời gian nghỉ và volume không tính hiệp khởi động.
4. Tìm món, chọn, đổi trang/từ khóa: món đã chọn vẫn còn. Kiểm tra đồ uống không
   chọn gram. Đổi dữ liệu trong kho: bữa cũ vẫn hiển thị snapshot.
5. Hai admin mở cấu hình: admin A lưu; admin B lưu bản cũ phải nhận 409.
6. Ẩn module với admin và user, kéo làm mới/đưa app về foreground để đối chiếu;
   thử ẩn toàn bộ rồi mở lại qua Thêm → Sắp xếp menu app.
