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
JWT_EXPIRATION_MS=604800000
ADMIN_EMAILS=admin@gmail.com
CORS_ALLOWED_ORIGINS=https://your-vercel-app.vercel.app
JPA_DDL_AUTO=update
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
VITE_API_URL=https://your-render-service.onrender.com/api
```

The frontend Axios client reads `VITE_API_URL`. If the variable is missing, it falls back to the Render API URL. Local development uses `.env.development`.

## Deployment Checklist

1. Create the Aiven PostgreSQL service and copy its host, port, database, username, and password.
2. Deploy backend on Render with `Project/fittrack_ai/backend` as root directory.
3. Set Aiven database and backend environment variables in Render.
4. Confirm `/api/health` returns `UP`.
5. Deploy frontend on Vercel with `Project/fittrack_ai/frontend` as root directory.
6. Set `VITE_API_URL` to the Render backend API URL.
7. Set `CORS_ALLOWED_ORIGINS` on Render backend to the Vercel frontend URL.
8. Register/login and test demo seed.
