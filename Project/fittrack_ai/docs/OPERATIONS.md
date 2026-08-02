# Vận hành production FitTrack

## Cấu hình bắt buộc

Render phải chạy profile `prod`, Flyway và Hibernate validate:

```env
SPRING_PROFILES_ACTIVE=prod
JPA_DDL_AUTO=validate
FLYWAY_ENABLED=true
SWAGGER_ENABLED=false
JWT_EXPIRATION_MS=900000
JWT_REFRESH_EXPIRATION_DAYS=30
AUTH_COOKIE_SECURE=true
INTERNAL_SCHEDULER_ENABLED=false
KEEP_ALIVE_ENABLED=false
```

Không đặt database password, JWT secret, Gemini key, Cloudinary secret hoặc SMTP password trong Git/Vercel/biến `VITE_*`. Các secret từng bị gửi qua chat phải được thu hồi và tạo lại tại Aiven, Google AI/OpenAI và Cloudinary trước lần deploy kế tiếp.

## Backup và Flyway

1. Cài PostgreSQL client (`pg_dump`, `pg_restore`).
2. Tạo bản backup Aiven trước mỗi lần deploy có migration:

```powershell
$env:PGPASSWORD = "<Aiven password hiện tại>"
.\scripts\backup-postgres.ps1 `
  -DatabaseHost "<host>" `
  -DatabasePort 26654 `
  -DatabaseName "defaultdb" `
  -DatabaseUser "avnadmin" `
  -OutputDirectory ".\backups"
Remove-Item Env:PGPASSWORD
```

Script tạo custom-format dump và dùng `pg_restore --list` để xác minh file đọc được. Lưu bản backup ở nơi mã hóa, không commit thư mục `backups/`.

Flyway chạy tự động khi backend khởi động. Database cũ chưa có `flyway_schema_history` được baseline tại version `0`; migration `V1` có tính lặp an toàn rồi các migration sau được áp dụng. Nếu migration thất bại, Render không khởi động vì JPA dùng `validate`; xem log Flyway, sửa migration tiến tới, không bật lại `ddl-auto=update`.

Khôi phục chỉ thực hiện khi đã dừng ghi dữ liệu và xác nhận đúng database đích:

```powershell
pg_restore --clean --if-exists --no-owner --no-privileges `
  --host <host> --port <port> --username <user> --dbname <database> <backup.dump>
```

## Scheduler ngoài Render

Backend miễn phí không thể tự giữ chính nó thức. Cấu hình UptimeRobot/cron ngoài hệ thống:

- `GET https://<render>/api/health` mỗi 10 phút để theo dõi/đánh thức dịch vụ.
- `POST https://<render>/api/internal/jobs/reminders` mỗi 5 phút với header `X-Job-Secret: <JOB_SECRET>`.

Nhắc nhở lưu `next_run_at`, khóa pessimistic và deduplication key nên có thể chạy bù sau khi Render ngủ mà không tạo thông báo trùng.

## Ảnh Cloudinary

```env
MEDIA_PROVIDER=cloudinary
MEDIA_ALLOWED_HOSTS=res.cloudinary.com
CLOUDINARY_CLOUD_NAME=<secret>
CLOUDINARY_API_KEY=<secret>
CLOUDINARY_API_SECRET=<secret>
```

Ảnh mới được kiểm tra MIME/magic bytes/kích thước rồi tải từ backend lên Cloudinary; PostgreSQL chỉ lưu HTTPS URL. Sau khi deploy, admin gọi nhiều lần:

```http
POST /api/admin/media/migrate?limit=25
```

cho tới khi `remaining` bằng `0`. Giữ backup trước khi chạy. QR thanh toán và endpoint media legacy yêu cầu đăng nhập.

## Xác thực và xoay secret

- Access token 15 phút, refresh token 30 ngày, refresh xoay vòng và có thể thu hồi.
- Token nằm trong cookie `HttpOnly`, `Secure`, `SameSite=Lax`; frontend gửi `X-Requested-With` cho request thay đổi dữ liệu.
- Đổi `JWT_SECRET` sẽ đăng xuất mọi phiên. Xoay theo chu kỳ 90 ngày hoặc ngay khi nghi ngờ lộ secret.
- Tài khoản admin cũ dùng `123456` chỉ được đăng nhập một lần và bị buộc đổi mật khẩu trước khi dùng chức năng khác.
- Production tắt Swagger. Nếu cần kiểm tra, bật tạm `SWAGGER_ENABLED=true` trong khoảng bảo trì rồi tắt lại.

## Vercel và cấu trúc repository

Root Directory chính thức của Vercel là `Project/fittrack_ai/frontend`. File `frontend/vercel.json` proxy `/api/*` về Render và rewrite mọi route khác về `index.html`, nên refresh `/foods`, `/workouts`, `/health` không còn 404. `frontend/fittrack-frontend/vercel.json` được giữ đồng bộ chỉ để chạy/deploy trực tiếp ứng dụng con khi cần.

Production Vercel dùng `VITE_API_MODE=proxy`; frontend luôn gọi `/api` qua rewrite cùng origin, kể cả khi dashboard Vercel còn giữ một `VITE_API_URL` tuyệt đối cũ. Cách này giữ refresh cookie cùng origin, phù hợp với CSP `connect-src 'self'` và không đưa secret backend vào bundle. Chỉ đặt `VITE_API_MODE=direct` cho image Docker frontend có CSP và backend URL riêng.

## Quan sát và xử lý lỗi

- Mọi response có `X-Request-Id`; log backend in cùng request ID.
- `/actuator/health` và `/actuator/prometheus` phục vụ health/metrics theo cấu hình Security.
- Có thể bật OTLP bằng `OTEL_EXPORT_ENABLED=true` và đặt `OTEL_EXPORTER_OTLP_TRACES_ENDPOINT` tới collector/Sentry-compatible collector.
- Admin xem sự kiện nhạy cảm tại `GET /api/admin/audit-events?page=0&size=20`.

Khi có HTTP 500, lấy `X-Request-Id` từ Network tab, tìm request ID đó trong Render Logs, sau đó kiểm tra exception gốc và Flyway history thay vì sửa dữ liệu thủ công.

## CI

Workflow `.github/workflows/fittrack-ci.yml` chạy backend test, migration trên PostgreSQL Testcontainers, frontend lint/Vitest/build, Playwright refresh-route, Docker build và secret scan cho mỗi push/PR.
