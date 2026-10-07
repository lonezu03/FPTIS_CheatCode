# FitTrack Release Checklist

## 1. Xác định chính xác bản phát hành

- [ ] Working tree chỉ chứa thay đổi của release.
- [ ] Ghi commit dự kiến deploy vào `CHANGELOG.md`.
- [ ] Backend `GET /api/health` sau deploy trả đúng `version` và `commit`.
- [ ] Không có secret, `.env`, certificate, backup hoặc SDK local trong diff.

## 2. Database

- [ ] Nếu có migration mới, backup Aiven và xác minh dump trước deploy.
- [ ] Không chỉnh migration đã chạy; luôn thêm migration tiến tới.
- [ ] CI chạy đủ `FlywayPostgresMigrationTest` và
  `PostgresApplicationContextTest`, không skip.
- [ ] Production đã đến đúng version bằng truy vấn read-only:

```sql
select installed_rank, version, description, installed_on, success
from flyway_schema_history
order by installed_rank desc
limit 10;
```

Source baseline hiện tại phải có version `18` thành công.

## 3. Verification

- [ ] Backend: `.\mvnw.cmd verify`.
- [ ] Web: `npm run lint`, `npm test`, `npm run build`.
- [ ] Route refresh: `npm run test:e2e` hoặc CI Playwright.
- [ ] Flutter (nếu release app): `flutter analyze`, `flutter test`, sau đó build
  bằng `tool/build_android.ps1`.
- [ ] Docker image backend build thành công.

## 4. Thứ tự deploy

1. Deploy backend trước, chờ Flyway và Hibernate validate thành công.
2. Kiểm tra `/actuator/health/liveness`, `/actuator/health/readiness` và
   `/api/health`.
3. Smoke test auth và API tương thích cũ.
4. Deploy web; build mobile sau khi backend contract đã ổn định.
5. Smoke test theo quyền: lunch-only user, user đầy đủ và admin.

## 5. Smoke test bắt buộc

- [ ] Login, refresh trang và logout.
- [ ] Lunch-only user chỉ thấy module được cấp và đặt được đơn hợp lệ.
- [ ] Admin xem được account/notification/lunch coordination.
- [ ] Một flow đọc và một flow ghi của Fitness, Health, Todo, Schedule, Quote
  với tài khoản có quyền tương ứng.
- [ ] Network response có `X-Request-Id`; lỗi có thể tìm lại trong Render logs.

## 6. Hoàn tất và rollback

- [ ] Theo dõi error rate, DB connections và readiness sau deploy.
- [ ] Ghi kết quả deploy vào `docs/CODEX_CONTEXT.md`.
- [ ] Chỉ tạo tag `fittrack-vYYYY.MM.DD.N` sau smoke test đạt.
- [ ] Rollback application bằng image/commit trước. Schema Flyway chỉ sửa tiến
  tới; không tự ý xóa migration hoặc restore DB khi hệ thống còn ghi dữ liệu.
