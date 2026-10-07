# Kiến trúc FitTrack

## Tổng quan

FitTrack là modular monolith có hai client dùng chung một API:

```text
React/Vercel ----\
                  -> Spring Boot/Render -> PostgreSQL/Aiven
Flutter mobile --/          |
                             +-> Brevo, Cloudinary, Gemini
```

- Web gọi `/api` qua Vercel same-origin proxy.
- Mobile gọi URL backend được cấp bằng `--dart-define=API_BASE_URL=...`.
- Backend là ranh giới xác thực, phân quyền, transaction và validation.
- Flyway là nguồn sự thật duy nhất của schema production.

## Ranh giới backend hiện tại

| Nhóm | Trách nhiệm |
| --- | --- |
| Auth/User | Phiên, OTP quên mật khẩu, hồ sơ, role và module permission |
| Lunch | Menu, đơn, quỹ/công nợ, payment request, review và thông báo cơm |
| Fitness | Bài tập, buổi tập, giáo án và thành tích |
| Nutrition/Health | Nhật ký ăn, thực phẩm, nước, chỉ số cơ thể, báo cáo và nhắc nhở |
| Planner | Todo tái diễn và Schedule event; calendar là read model hợp nhất |
| Quote | Kho câu nói cá nhân và vòng quay câu nói hằng ngày |
| Notification | In-app notification, email opt-in và playbook admin |
| Assistant | Gemini server-side và các hành động cần user xác nhận |
| Common/Audit | Security filters, lỗi chuẩn, media, request ID và audit trail |

Các module vẫn có một số luồng liên kết có chủ đích: Lunch ghi dinh dưỡng;
Dashboard tổng hợp nhiều module; Assistant đọc dữ liệu theo quyền để đề xuất.
Các liên kết này phải được mô tả trước khi áp dụng Spring Modulith verification.

## Luồng xác thực web

```text
Login -> backend kiểm tra mật khẩu
      -> đặt access/refresh cookie HttpOnly
      -> trả access token ngắn hạn cho memory
      -> client gọi API
401   -> refresh cookie được xoay vòng
      -> request gốc được thử lại một lần
```

Không lưu credential trong `localStorage`. Browser route protection chỉ phục vụ
UX; backend tải user và kiểm tra permission ở mỗi request.

## Dữ liệu và transaction

- Repository chỉ được gọi qua service transaction phù hợp.
- API dùng DTO/mapper, không serialize entity trực tiếp.
- Soft delete giữ lịch sử Food/Exercise và các dữ liệu tham chiếu.
- Giao dịch Lunch lưu ledger và audit; idempotency tài chính đầy đủ là giai đoạn
  hardening tiếp theo, không thuộc release-baseline này.
- Dữ liệu dinh dưỡng phân biệt `UNLOGGED`, `PARTIAL`, `COMPLETE`, `FASTING`; dữ
  liệu thiếu không được diễn giải thành giá trị 0.

## Vận hành

- `X-Request-Id` được trả về và ghi cùng backend logs.
- `/actuator/health/liveness` không phụ thuộc dịch vụ ngoài.
- `/actuator/health/readiness` phụ thuộc application readiness và DB.
- `/api/health` trả version/commit giúp đối chiếu source đang chạy.
- Prometheus và OpenTelemetry đã có hạ tầng; business metrics và dashboard cảnh
  báo là giai đoạn tiếp theo.

Chi tiết deploy và xử lý sự cố nằm trong [OPERATIONS.md](OPERATIONS.md).
