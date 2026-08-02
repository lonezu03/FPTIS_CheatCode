# Deployment Guide

## Render + Vercel + Aiven PostgreSQL

This is the simplest deployment setup for a portfolio project:

- Backend: Render Web Service
- Database: Aiven for PostgreSQL
- Frontend: Vercel

## Backend on Render

Create a new Render Web Service.

Recommended settings:

```txt
Service type: Web Service
Runtime: Docker
Root directory: Project/fittrack_ai/backend
Dockerfile path: Dockerfile
Port: 8080
```

Use the root `backend/Dockerfile`. It builds the current Spring Boot backend, including the lunch-ordering module.

### Backend Environment Variables

```txt
SERVER_PORT=8080
SPRING_DATASOURCE_URL=jdbc:postgresql://<AIVEN_HOST>:<AIVEN_PORT>/<AIVEN_DATABASE>?sslmode=require
SPRING_DATASOURCE_USERNAME=avnadmin
SPRING_DATASOURCE_PASSWORD=<aiven-password>
JWT_SECRET=<very-long-secret>
SPRING_PROFILES_ACTIVE=prod
JWT_EXPIRATION_MS=900000
JWT_REFRESH_EXPIRATION_DAYS=30
ADMIN_EMAILS=admin@gmail.com
CORS_ALLOWED_ORIGINS=https://your-vercel-app.vercel.app
JPA_DDL_AUTO=validate
FLYWAY_ENABLED=true
SWAGGER_ENABLED=false
INTERNAL_SCHEDULER_ENABLED=false
KEEP_ALIVE_ENABLED=false
JOB_SECRET=<random-job-secret>
JPA_SHOW_SQL=false
```

### Health Check

```txt
GET https://your-render-service.onrender.com/api/health
```

Expected response:

```json
{
  "status": "UP",
  "timestamp": "2026-05-31T..."
}
```

## Database on Aiven

Create an Aiven for PostgreSQL service, then copy the service Overview connection values into Render. Use the JDBC URL below; `sslmode=require` is required for Aiven TLS connections.

Use the JDBC format:

```txt
jdbc:postgresql://HOST:PORT/DATABASE?sslmode=require
```

Do not commit the Aiven password or JWT secret. Enter them only as secret environment variables in Render.

## Frontend on Vercel

Create a new Vercel project from the same repository.

Recommended settings:

```txt
Framework: Vite
Root directory: Project/fittrack_ai/frontend
Build command: npm run build
Output directory: dist
```

### Frontend Environment Variables

```txt
VITE_API_MODE=proxy
VITE_API_URL=/api
```

Vercel dùng proxy cùng origin. `VITE_API_MODE=proxy` buộc frontend gọi `/api`, kể cả khi project còn lưu một `VITE_API_URL` tuyệt đối cũ. Local development dùng `.env.development`; image Docker frontend dùng `VITE_API_MODE=direct`.

## Deployment Checklist

1. Create the Aiven PostgreSQL service and copy its host, port, database, username, and password.
2. Deploy backend on Render with `Project/fittrack_ai/backend` as root directory.
3. Set Aiven database and backend environment variables in Render.
4. Confirm `/api/health` returns `UP`.
5. Deploy frontend on Vercel with `Project/fittrack_ai/frontend` as root directory.
6. Set `VITE_API_MODE=proxy` và `VITE_API_URL=/api` trên Vercel.
7. Set `CORS_ALLOWED_ORIGINS` on Render backend to the Vercel frontend URL.
8. Cấu hình cron ngoài gọi `/api/health` và job nhắc nhở như hướng dẫn vận hành.
9. Register/login and test demo seed.

Quy trình backup, Flyway, Cloudinary, xoay secret và xử lý sự cố đầy đủ nằm trong [OPERATIONS.md](OPERATIONS.md).
