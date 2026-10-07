# FitTrack Security Baseline

## Bí mật và dữ liệu nhạy cảm

- Chỉ đặt database password, JWT/Gemini/Brevo/Cloudinary key trong secret store
  của môi trường triển khai.
- Không commit `.env`, token, certificate, database dump hoặc giá trị thật vào
  tài liệu/test/log.
- Mọi API key từng chia sẻ ở nơi công khai hoặc qua chat phải được thu hồi và
  tạo mới.
- Biến `VITE_*` là public; tuyệt đối không chứa secret.

## Xác thực và authorization

- Web dùng cookie HttpOnly qua proxy cùng origin; access token trong memory.
- Mobile lưu refresh credential bằng secure storage.
- Backend kiểm tra role, trạng thái account và module permission trên request.
- Service lấy owner từ authenticated principal; không tin `userId` tùy ý từ
  client cho dữ liệu cá nhân.
- Forgot-password chỉ gửi OTP tới email đã lưu của tài khoản.

## API và vận hành

- Request thay đổi dữ liệu từ web phải có `X-Requested-With`.
- Production tắt Swagger trừ thời gian bảo trì được kiểm soát.
- Actuator health probe public nhưng không hiển thị chi tiết; info/prometheus
  yêu cầu admin.
- Lỗi production được điều tra bằng `X-Request-Id`, không ghi secret hoặc payload
  nhạy cảm vào log.
- Thao tác admin quan trọng phải có audit event.

## Kiểm tra trước release

- CI quét secret và chạy security/unit/integration test.
- Giai đoạn hardening kế tiếp phải bổ sung ma trận BOLA: User A không thể đọc,
  sửa hoặc xóa tài nguyên của User B ở từng module.
- Giao dịch tài chính Lunch cần idempotency backend trước khi coi là release
  hardened hoàn chỉnh.

Không báo lỗ hổng kèm credential trong issue công khai. Thu hồi credential trước,
sau đó cung cấp request ID, thời gian và bước tái hiện qua kênh riêng của owner.
