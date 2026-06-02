# Deployment Guide

## Option 1: Render + Vercel

This is the simplest deployment setup for a portfolio project:

- Backend: Render Web Service
- Database: Render PostgreSQL
- Frontend: Vercel

## Backend on Render

Create a new Render Web Service.

Recommended settings:

```txt
Service type: Web Service
Runtime: Docker
Root directory: backend
Dockerfile path: Dockerfile
Port: 8080
```

The repository also contains `backend/demo/Dockerfile` for local Docker Compose usage. On Render, use `backend/Dockerfile` with root directory `backend`; it copies the actual Spring Boot app from `backend/demo`.

### Backend Environment Variables

```txt
SERVER_PORT=8080
SPRING_DATASOURCE_URL=jdbc:postgresql://dpg-d8eqo6l7vvec73du09vg-a:5432/fittrack_db_b1ri
SPRING_DATASOURCE_USERNAME=fittrack_user
SPRING_DATASOURCE_PASSWORD=<password>
JWT_SECRET=<very-long-secret>
JWT_EXPIRATION_MS=604800000
CORS_ALLOWED_ORIGINS=https://your-vercel-app.vercel.app
JPA_DDL_AUTO=update
JPA_SHOW_SQL=false
```

### Health Check

```txt
GET https://your-render-backend.onrender.com/api/health
```

Expected response:

```json
{
  "status": "UP",
  "timestamp": "2026-05-31T..."
}
```

## Database on Render

Create a Render PostgreSQL database and copy its internal connection details into the backend environment variables.

Use the JDBC format:

```txt
jdbc:postgresql://HOST:PORT/DATABASE
```

Current Render database values:

```txt
Host: dpg-d8eqo6l7vvec73du09vg-a
Port: 5432
Database: fittrack_db_b1ri
Username: fittrack_user
JDBC URL: jdbc:postgresql://dpg-d8eqo6l7vvec73du09vg-a:5432/fittrack_db_b1ri
```

Do not commit the database password or JWT secret. Set them in Render environment variables.

## Frontend on Vercel

Create a new Vercel project from the same repository.

Recommended settings:

```txt
Framework: Vite
Root directory: frontend/fittrack-frontend
Build command: npm run build
Output directory: dist
```

### Frontend Environment Variables

```txt
VITE_API_URL=https://your-render-backend.onrender.com/api
```

The frontend Axios client reads `VITE_API_URL` and falls back to `http://localhost:8080/api` for local development.

## Deployment Checklist

1. Deploy Render PostgreSQL.
2. Deploy backend on Render with `backend` as root directory.
3. Set backend env vars.
4. Confirm `/api/health` returns `UP`.
5. Deploy frontend on Vercel with `frontend/fittrack-frontend` as root directory.
6. Set `VITE_API_URL` to the Render backend API URL.
7. Set `CORS_ALLOWED_ORIGINS` on Render backend to the Vercel frontend URL.
8. Register/login and test demo seed.
