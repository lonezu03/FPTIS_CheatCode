# Quản lý nhà trọ

Ứng dụng chạy trên máy cá nhân để quản lý khu trọ, phòng, khách thuê, hợp đồng, chỉ số điện nước, hóa đơn và thanh toán. Giao diện và dữ liệu sử dụng tiếng Việt và đồng Việt Nam.

## Chạy ứng dụng

Yêu cầu Node.js 22.13 trở lên có hỗ trợ `node:sqlite` (đã kiểm tra với Node 23). Giao diện dùng React và Vite; API dùng Node.js và SQLite.

```powershell
cd rental-management
npm install
npm start
```

Lệnh `npm start` build giao diện rồi chạy API và web tại http://127.0.0.1:3001. Dừng ứng dụng bằng `Ctrl+C`. Dữ liệu nằm trong `data/rental.sqlite`; sao lưu tệp này khi ứng dụng đã dừng. Thư mục dữ liệu được loại khỏi Git vì có thể chứa thông tin cá nhân.

Khi phát triển, chạy `npm run dev:api` và `npm run dev` trong hai terminal; mở địa chỉ Vite tại http://127.0.0.1:5173. Vite chuyển các yêu cầu `/api` tới API tại cổng 3001.

Chạy kiểm thử: `npm test`. Có thể đổi cổng bằng biến môi trường `PORT` và vị trí dữ liệu bằng `DATA_DIR`.

## Cách sử dụng

1. Tạo khu trọ, phòng và người thuê.
2. Tạo hợp đồng cho phòng. Các khoảng thời gian thuê của cùng phòng không được giao nhau.
3. Nhập chỉ số điện nước và đơn giá theo từng phòng, từng tháng trước khi lập hóa đơn.
4. Lập hóa đơn và ghi nhận từng khoản thanh toán; hệ thống tính số tiền còn nợ.

Giá thuê và tiền điện nước được lưu tại thời điểm tạo hóa đơn; các thay đổi về sau không tự cập nhật hóa đơn đã tạo. Hợp đồng đang thuê dựa trên trạng thái được chọn, không tự chuyển theo ngày.

## Tài khoản và thanh toán

Lần đầu chạy, tạo tài khoản chủ trọ trên màn hình khởi tạo. Dữ liệu cũ chưa có chủ sở hữu sẽ được gắn với tài khoản đầu tiên. Chủ trọ tạo tài khoản người thuê gắn với hồ sơ và tạo nhân viên với quyền theo từng khu. Có thể tạo thêm chủ trọ độc lập; mỗi chủ trọ chỉ quản lý dữ liệu của mình. Tài khoản người thuê xem lịch sử các hợp đồng được liên kết và gửi yêu cầu xác nhận chuyển khoản; số tiền chỉ được ghi nhận sau khi người có quyền duyệt.

Có thể chọn phân bổ khoản thu vào tiền phòng, điện, nước hoặc dịch vụ. Hóa đơn có giảm trừ chỉ hỗ trợ thanh toán chung; khoản thanh toán cũ hoặc thanh toán chung không được tự suy đoán là trả cho hạng mục nào. Chủ trọ nhập thông tin ngân hàng và đường dẫn ảnh QR HTTPS. Thông báo được lưu trong ứng dụng; hóa đơn mới và các hạn trong ba ngày được nhắc khi server đang chạy.

## Giới hạn hiện tại

Ứng dụng mặc định chạy cục bộ. Có ứng dụng Flutter người thuê tại `mobile/`; xem hướng dẫn ở đó. Tích hợp thông báo đẩy FCM cần cấu hình Firebase ở cả hai phía và chưa được kiểm tra với thiết bị thật. Server bật gửi bằng `FCM_ENABLED=true`, `FIREBASE_PROJECT_ID` và Application Default Credentials; không đưa thông tin xác thực vào Git. Gửi push là best-effort, không tự thử lại khi lỗi.

Chưa có tải ảnh minh chứng, hoàn tiền, đảo khoản thanh toán hay sổ cọc; lịch sử kiểm toán chưa bao phủ toàn bộ thao tác tài chính. Hóa đơn chưa thanh toán có thể bị xóa. Chưa đưa lên Internet: cần hoàn thiện bảo mật, sao lưu/khôi phục, kiểm thử độc lập và cấu hình HTTPS/cookie trước khi sử dụng thật. Giới hạn thử đăng nhập hiện chỉ lưu trong bộ nhớ của một tiến trình. `npm audit` hiện báo sáu cảnh báo moderate trong các phụ thuộc gián tiếp của Firebase; `npm audit fix` chưa khắc phục được. Các yêu cầu và hướng mở rộng nằm trong `docs/YEU_CAU_THIET_KE.md`.
