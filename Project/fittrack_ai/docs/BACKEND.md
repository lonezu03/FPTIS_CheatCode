# Backend FitTrack

## Công nghệ và cách chạy

- Java 21, Spring Boot 4, Maven Wrapper.
- Spring MVC, Spring Security, JWT access/refresh và cookie HttpOnly.
- Spring Data JPA/Hibernate, PostgreSQL và Flyway.
- H2 chỉ dùng cho profile `local` và phần lớn test cô lập; PostgreSQL
  Testcontainers là cổng kiểm tra migration/production compatibility.
- Actuator, Prometheus và OpenTelemetry cho health, metric và trace.

Backend đang hoạt động nằm trực tiếp trong `backend/`. Không sử dụng bản
`backend/demo/` cũ.

```powershell
cd backend
.\mvnw.cmd spring-boot:run -Dspring-boot.run.profiles=local
```

Backend local mặc định: `http://localhost:8081`.

## Kiến trúc

Backend là modular monolith, tổ chức theo feature:

```text
controller -> service -> repository -> PostgreSQL
                |
              mapper -> DTO
```

Các module chính gồm `auth`, `user`, `lunch`, `workout`, `workoutplan`,
`nutrition`, `bodytracking`, `health`, `todo`, `schedule`, `quote`,
`notification`, `dashboard`, `report`, `recommendation`, `achievement`,
`assistant`, `audit` và hạ tầng dùng chung trong `common`.

Controller không trả JPA entity trực tiếp. Mọi thay đổi schema production phải
được thêm bằng migration mới tại `src/main/resources/db/migration`; production
dùng `ddl-auto=validate`.

## Xác thực và phân quyền

- Access token sống ngắn; refresh token được xoay vòng và có thể thu hồi.
- Web dùng cookie `HttpOnly`, `Secure`, `SameSite=Lax` qua proxy cùng origin.
- Mobile lưu refresh credential trong Keystore/Keychain cho đến khi logout.
- Authorization được kiểm tra tại backend bằng role và module permission; việc
  ẩn route ở client không phải ranh giới bảo mật.
- Tài khoản mới active và chỉ có quyền Đặt cơm. Các module khác cần admin cấp.
- Endpoint admin yêu cầu role `ADMIN`; dữ liệu cá nhân luôn phải giới hạn theo
  authenticated user.

Endpoint public gồm auth flow, media public được cho phép, `/api/health` và các
Actuator health probe. `/actuator/info` và `/actuator/prometheus` chỉ dành cho
admin.

## Health và nhận diện bản deploy

- `GET /api/health`: kiểm tra kết nối DB, trả `version`, `commit` và timestamp.
- `GET /actuator/health/liveness`: chỉ xác nhận JVM/app còn sống.
- `GET /actuator/health/readiness`: xác nhận app sẵn sàng nhận traffic và DB UP.
- `GET /actuator/health`: health tổng hợp.

SMTP health mặc định tắt vì production gửi mail qua Brevo REST. Chỉ đặt
`MAIL_HEALTH_ENABLED=true` nếu deployment thực sự dùng SMTP và muốn SMTP tham
gia health tổng hợp. Render nên dùng `/actuator/health/readiness`; dịch vụ theo
dõi bên ngoài có thể gọi `/api/health`.

Render cấp commit qua `RENDER_GIT_COMMIT`. Ngoài Render có thể đặt `GIT_COMMIT`;
nếu không có, health trả `unknown`.

## Test và release gate

```powershell
cd backend
.\mvnw.cmd test
.\mvnw.cmd verify
```

Hai suite `FlywayPostgresMigrationTest` và `PostgresApplicationContextTest`
chạy PostgreSQL thật qua Testcontainers. Local không có Docker được phép skip,
nhưng CI chạy `scripts/verify_postgres_test_reports.py` và thất bại nếu một trong
hai suite bị thiếu hoặc bị skip.

Xem thêm [API.md](API.md), [OPERATIONS.md](OPERATIONS.md) và
[RELEASE_CHECKLIST.md](RELEASE_CHECKLIST.md).
