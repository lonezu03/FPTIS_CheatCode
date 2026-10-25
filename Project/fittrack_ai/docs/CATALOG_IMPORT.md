# Nhập nhanh kho bài tập và thực phẩm

Chức năng web dành cho ADMIN, mở **Kho bài tập / Kho thực phẩm → Nhập hàng loạt**.
Người dùng thường vẫn phải gửi bài tập/thực phẩm qua quy trình duyệt hiện có.

## Cách sử dụng

1. Tải mẫu CSV hoặc XLSX. Có thể xuất kho hiện tại để lấy ID khi cần cập nhật.
2. Điền file hoặc sao chép bảng từ Excel và dán vào hộp nhập.
3. Ánh xạ tiêu đề cột sang trường hệ thống; chọn bỏ qua rõ ràng cho cột không dùng.
4. Nhấn kiểm tra. Đọc lỗi, cảnh báo trùng, giá trị chuẩn hóa và phần trước/sau.
5. Chọn thêm mới, cập nhật hoặc bỏ qua từng dòng; tích xác nhận rồi nhập.
6. Xem lịch sử lô và tải danh sách lỗi. Sửa file rồi xem trước lại nếu cần.

Lỗi dữ liệu phải được sửa trước khi nhập dòng đó. Có thể bỏ qua dòng lỗi để
nhập các dòng hợp lệ. Một lô được ghi trong một transaction; gửi lại cùng lựa
chọn không tạo thêm bản ghi. Bản xem trước hết hạn sau 24 giờ.

## Dữ liệu mẫu

Bài tập (cột `description` tối đa 2.000 ký tự):

```csv
name,muscleGroup,equipment,description
Smith Squat,Legs,Smith Machine,Giữ cột sống ổn định và kiểm soát biên độ
Incline Dumbbell Press,Chest,Dumbbell,Điều chỉnh ghế nghiêng phù hợp
```

Thực phẩm:

```csv
name,unit,basis,servingSizeGrams,calories,protein,carbs,fat
Ức gà chín,150g,PER_100G,150,165,31,0,3.6
Sữa không đường,200ml,PER_SERVING,200,120,6,9,6
```

- `PER_SERVING`: dinh dưỡng của một khẩu phần. `PER_100G`: số liệu trên 100 g;
  hệ thống chuyển sang khẩu phần bằng `servingSizeGrams` và hiển thị kết quả.
  Không dùng `PER_100G` để suy diễn mật độ cho đồ uống tính ml.
- Năng lượng: kcal; protein/carbs/fat/fiber/sugar: g; water: ml;
  sodium/potassium/calcium/iron/vitaminC: mg.
- Vi chất không biết để trống, không điền 0 thay cho dữ liệu chưa biết.
- Có thể bổ sung barcode, nguồn dữ liệu và imageUrl. URL ảnh phải qua kiểm tra
  nguồn HTTPS được backend cho phép; hệ thống không tự tạo hoặc tải ảnh từ URL.
- Chênh lệch kcal với công thức 4×đạm + 4×carb + 9×béo là cảnh báo kiểm tra nhãn,
  không tự sửa giá trị hoặc chặn chỉ vì công thức này.

## Cập nhật và chống ghi nhầm

- Thêm mới: để trống `id`. Cập nhật: dùng ID thật từ file xuất.
- Dòng có ID và dòng nghi trùng mặc định bỏ qua, phải chủ động chọn cập nhật/thêm.
- Ô tùy chọn để trống khi cập nhật giữ giá trị cũ; dùng lựa chọn xóa trường để
  xóa các trường cho phép để trống. Không tự mở lại mục lưu trữ hoặc thay duyệt.
- Bản ghi thay đổi sau lúc xem trước sẽ trả xung đột, cần xem trước lại.
- Batch lưu người thao tác, thời gian, SHA-256 nguồn và kết quả từng dòng.
  Chống gửi lại áp dụng trong cùng batch, không phải khóa trùng toàn cục giữa
  các batch khác nhau nhập đồng thời.
- File xuất để trống ảnh nhằm tránh mang dữ liệu ảnh nhúng lớn vào bảng;
  nhập lại ô ảnh trống sẽ giữ ảnh hiện tại. Chưa có hoàn tác cả lô tự động.

## Giới hạn

Tối đa 500 dòng dữ liệu, 50 cột, file 2 MB, XLSX giải nén 5 MB. XLSX tiêu chuẩn
dùng worksheet đầu (`sheet1.xml`); không nhận macro, công thức, external link.
File lớn chia thành nhiều lô; sửa dữ liệu tại file nguồn rồi xem trước lại.

## Triển khai và kiểm tra

Triển khai backend trước để Flyway chạy V32–V34, sau đó web. Sao lưu DB và kiểm
tra migration trên PostgreSQL staging trước production. Không cần thêm secret
hoặc dùng AI cho import. Không có cập nhật/build mobile trong đợt này.

Kiểm tra bằng ADMIN: nhập 2 bài tập, 2 thực phẩm; xuất lấy ID; sửa 1 dòng và
kiểm tra ô trống giữ vi chất/ảnh; thử dòng trùng/lỗi và gửi lại cùng batch.
Đăng nhập USER kiểm tra không thấy nút import và API từ chối truy cập.
Tạo giáo án, bắt đầu tập rồi hủy: lịch sử không được tăng. Hoàn thành vài hiệp,
sửa lại buổi tập; kiểm tra hiệp khởi động không cộng volume chính.
Thêm bữa ăn, đổi tên/thành phần thực phẩm trong kho: bữa cũ giữ snapshot.
