# FitTrack Mobile

Ứng dụng Flutter dùng chung Spring Boot backend với FitTrack Web.

## Phạm vi hiện tại

- Đăng nhập, đăng ký/xác thực email, quên mật khẩu bằng OTP và đổi mật khẩu lần đầu.
- Đặt cơm: xem menu, số dư/nợ, chọn cơm 2 món hoặc món đơn, đặt và hủy đơn.
- Fitness: nhật ký buổi tập và nhật ký dinh dưỡng.
- Sức khỏe: tổng hợp 30 ngày, chỉ số cơ thể và lời nhắc.
- Thông báo trong ứng dụng.
- Admin: quyền tài khoản, import menu/gửi email và gửi thông báo toàn công ty.
- Chatbot chưa được tích hợp trong bản này.

## Chạy với backend local

Flutter tự dùng:

- Android emulator: `http://10.0.2.2:8081/api`
- iOS simulator/Web: `http://localhost:8081/api`

Chạy trên điện thoại thật trong cùng Wi-Fi (thay IP bằng IP máy chạy backend):

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8081/api
```

Backend phải lắng nghe `0.0.0.0:8081`; mở firewall cho cổng 8081 nếu điện thoại không kết nối được.

## Chạy với Render

```bash
flutter run --dart-define=API_BASE_URL=https://https-github-com-lonezu03-fptis.onrender.com/api
```

Tạo APK release:

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://https-github-com-lonezu03-fptis.onrender.com/api
```

Trên máy hiện tại có thể dùng script một lệnh (PowerShell):

```powershell
powershell -ExecutionPolicy Bypass -File .\tool\build_android.ps1
```

Build bản debug để test với backend trên máy trong cùng Wi-Fi:

```powershell
powershell -ExecutionPolicy Bypass -File .\tool\build_android.ps1 -Mode debug -ApiBaseUrl http://192.168.1.10:8081/api
```

File xuất ra tại `build/app/outputs/flutter-apk/app-release.apk`.

## Lưu ý release

- Thay debug signing bằng Android upload keystore trước khi phát hành Google Play.
- Không đặt JWT secret, Brevo key, Gemini key hay database password trong app. Chúng chỉ nằm ở backend/Render Environment.
- `android:usesCleartextTraffic="true"` hiện được giữ để test backend HTTP local. Khi chỉ dùng HTTPS production, nên tạo network security config riêng cho debug.
