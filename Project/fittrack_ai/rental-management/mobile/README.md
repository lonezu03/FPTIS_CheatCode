# Ứng dụng người thuê Nhà Mây

Flutter cho Android và iOS, dùng API thật. Tạo tài khoản người thuê từ web quản lý trước.

```powershell
flutter pub get
flutter run --dart-define=API_BASE_URL=https://YOUR_HOST/api
flutter analyze
flutter test
```

Bản debug có thể dùng HTTP để thử nội bộ (Android emulator dùng `http://10.0.2.2:3001/api`); bản phát hành yêu cầu HTTPS. Phiên đăng nhập được lưu bằng secure storage và xóa khi đăng xuất hoặc máy chủ trả 401.

Thông báo trong ứng dụng lấy từ API; thông báo đẩy Firebase chưa được cấu hình và cần cấu hình Firebase/APNs của dự án trước khi sử dụng.

Thông báo đẩy là tùy chọn. Cấu hình Firebase cho Android/iOS và truyền `FIREBASE_API_KEY`, `FIREBASE_APP_ID`, `FIREBASE_PROJECT_ID`, `FIREBASE_SENDER_ID` qua `--dart-define`; iOS cần thêm `FIREBASE_IOS_BUNDLE_ID`, bật Push Notifications và cấu hình APNs trong Firebase. Backend cũng cần thông tin gửi FCM. Khi thiếu cấu hình, ứng dụng vẫn dùng thông báo trong ứng dụng. Cần thử nhận thông báo trên thiết bị thật sau khi hoàn tất cấu hình.
