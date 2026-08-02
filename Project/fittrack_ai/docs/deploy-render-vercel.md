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
CORS_ALLOWED_ORIGINS=https://fptis-cheat-code.vercel.app
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
APP_FRONTEND_URL=https://fptis-cheat-code.vercel.app
MAIL_ENABLED=true
MAIL_HOST=smtp.gmail.com
MAIL_PORT=587
MAIL_USERNAME=<smtp-account>
MAIL_PASSWORD=<gmail-app-password-or-smtp-password>
MAIL_FROM=<verified-sender-address>
```

Use Aiven PostgreSQL for the database. Copy the host, port, database name, username, and password from the Aiven service Overview page.

Set Render's Health Check Path to `/api/health`. Dùng cron/UptimeRobot bên ngoài
để gọi health và `/api/internal/jobs/reminders`; backend không thể tự đánh thức
chính nó khi Render đã cho ngủ. Do not put `GEMINI_API_KEY` in `render.yaml`,
Git, Vercel, or any `VITE_` environment variable.

`MAIL_PASSWORD` phải là mật khẩu ứng dụng SMTP, không dùng mật khẩu đăng nhập
email thông thường. Nếu chưa cấu hình mail, đặt `MAIL_ENABLED=false`; đăng ký
vẫn tạo tài khoản nhưng người dùng sẽ chưa nhận được liên kết xác thực.

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
