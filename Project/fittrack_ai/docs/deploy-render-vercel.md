# Deploy Option 1: Render + Vercel

## Backend: Render

- Service type: Web Service
- Runtime: Docker
- Root directory: `Project/fittrack_ai/backend`
- Dockerfile path: `Dockerfile`
- Port: `8080`

Environment variables:

```env
SPRING_DATASOURCE_URL=jdbc:postgresql://<AIVEN_HOST>:<AIVEN_PORT>/<AIVEN_DATABASE>?sslmode=require
SPRING_DATASOURCE_USERNAME=avnadmin
SPRING_DATASOURCE_PASSWORD=<set-in-render-dashboard>
JWT_SECRET=<set-in-render-dashboard>
SPRING_PROFILES_ACTIVE=prod
JWT_EXPIRATION_MS=900000
JWT_REFRESH_EXPIRATION_DAYS=30
CORS_ALLOWED_ORIGINS=https://datcom-nhalam.vercel.app
JPA_DDL_AUTO=validate
FLYWAY_ENABLED=true
SWAGGER_ENABLED=false
JPA_SHOW_SQL=false
GEMINI_API_KEY=<new-key-set-only-in-render-dashboard>
GEMINI_MODEL=gemini-3.6-flash
ASSISTANT_REQUESTS_PER_MINUTE=6
KEEP_ALIVE_ENABLED=false
INTERNAL_SCHEDULER_ENABLED=false
JOB_SECRET=<random-secret-used-by-external-cron>
APP_FRONTEND_URL=https://datcom-nhalam.vercel.app
MAIL_ENABLED=true
MAIL_PROVIDER=brevo
BREVO_API_KEY=<set-only-in-render-dashboard>
BREVO_API_URL=https://api.brevo.com/v3/smtp/email
MAIL_FROM=<verified-sender-address>
MAIL_SENDER_NAME=FitTrack
MAIL_API_CONNECT_TIMEOUT_MS=10000
MAIL_API_READ_TIMEOUT_MS=15000
```

Use Aiven PostgreSQL for the database. Copy the host, port, database name, username, and password from the Aiven service Overview page.

Set Render's Health Check Path to `/api/health`. Dùng cron/UptimeRobot bên ngoài
để gọi health và `/api/internal/jobs/reminders`; backend không thể tự đánh thức
chính nó khi Render đã cho ngủ. Do not put `GEMINI_API_KEY` in `render.yaml`,
Git, Vercel, or any `VITE_` environment variable.

Render Free chặn outbound SMTP trên các cổng `25`, `465` và `587`, vì vậy production
phải dùng Brevo Email API qua HTTPS. Tạo tài khoản Brevo, thêm sender, nhập mã xác
minh gửi về địa chỉ sender, tạo API key rồi đặt `BREVO_API_KEY` trên Render.
`MAIL_FROM` phải trùng sender đã xác minh trong Brevo. Không đưa API key vào Git,
Vercel hoặc biến môi trường `VITE_*`.

SMTP vẫn dùng được khi chạy local hoặc trên Render trả phí bằng cách đặt
`MAIL_PROVIDER=smtp` cùng `MAIL_HOST`, `MAIL_PORT`, `MAIL_USERNAME`,
`MAIL_PASSWORD` và `MAIL_FROM`.

Production yêu cầu email để xác thực đăng ký. Vì vậy nếu `MAIL_ENABLED=false`
hoặc thiếu API key/sender, đăng ký và quên mật khẩu sẽ trả `503`
thay vì âm thầm tạo tài khoản không thể xác thực. Sau khi deploy, đăng nhập admin
và dùng **Quản lý thông báo > Gửi email thử cho tôi**; nếu Brevo từ chối, Render
log sẽ ghi HTTP status và thông báo an toàn nhưng không ghi API key.

## Frontend: Vercel

- Framework: Vite
- Root directory: `Project/fittrack_ai/frontend`
- Build command: `npm run build`
- Output directory: `dist`

Environment variables:

```env
VITE_API_MODE=proxy
VITE_API_URL=/api
```

Backend production:

```txt
BACKEND_URL=https://your-render-service.onrender.com
API_BASE_URL=https://your-render-service.onrender.com/api
Swagger=https://your-render-service.onrender.com/swagger-ui/index.html
```
