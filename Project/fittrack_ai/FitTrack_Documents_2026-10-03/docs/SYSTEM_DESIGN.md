# FitTrack System Design

## Mục tiêu

FitTrack phục vụ nhóm công ty nhỏ với quy trình đặt cơm hằng ngày, đồng thời cung
cấp fitness, dinh dưỡng, sức khỏe, planner và trợ lý cá nhân trên web/mobile.
Ưu tiên là đúng dữ liệu, phân quyền rõ, chi phí vận hành thấp và có thể truy vết.

## Thành phần triển khai

| Thành phần | Nền tảng | Trách nhiệm |
| --- | --- | --- |
| React web | Vercel | SPA, proxy same-origin `/api`, cookie auth |
| Flutter | Android/iOS | Mobile UX, secure session, local notification |
| Spring Boot | Render | API, authorization, transaction, scheduler endpoint |
| PostgreSQL | Aiven | Nguồn dữ liệu bền vững, ledger, audit, notification |
| Brevo | External REST | Email giao dịch và broadcast opt-in |
| Cloudinary | External | Lưu media, DB chỉ giữ HTTPS URL |
| Gemini | External | Trợ lý server-side, user xác nhận trước khi ghi |

## Các quyết định chính

1. Modular monolith thay vì microservice để giữ transaction đơn giản và phù hợp
   quy mô hiện tại.
2. Flyway + Hibernate validate để schema có lịch sử và deploy dự đoán được.
3. Backend authorization; frontend permission chỉ cải thiện UX.
4. Lunch ledger giữ fund/debt và lịch sử thay vì sửa số dư không dấu vết.
5. Web same-origin proxy giảm CORS/cookie phức tạp và che topology, không được
   xem là biện pháp che API hay authorization.
6. Request ID nối browser error với backend logs.
7. Missing nutrition data là unknown, không phải zero.

## Luồng release

```text
commit -> CI test/build/secret scan -> backup nếu có migration
       -> backend/Flyway -> health + smoke test -> web -> mobile release
       -> production verification -> release tag
```

CI phải chứng minh Testcontainers PostgreSQL đã chạy. Health tách liveness khỏi
readiness để lỗi DB không khiến hệ thống hiểu sai JVM crash, trong khi traffic
chỉ được gửi khi DB sẵn sàng.

## Rủi ro đang theo dõi

- Idempotency chưa phủ mọi thao tác tài chính Lunch.
- BOLA regression tests chưa phủ đủ tất cả module.
- Rate limiter auth hiện theo memory của từng instance.
- Business metrics/alert chưa hoàn chỉnh.
- OpenAPI chưa được dùng làm compatibility gate cho web/mobile.
- External remote push cần Firebase; mobile hiện chủ yếu dùng local notification
  và polling/background work.

Các rủi ro này được xử lý theo từng batch độc lập để tránh trộn thay đổi kiến
trúc với nghiệp vụ đang dùng trên production.
