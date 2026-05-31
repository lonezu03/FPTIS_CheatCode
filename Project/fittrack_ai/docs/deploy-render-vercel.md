# Deploy Option 1: Render + Vercel

## Backend: Render

- Service type: Web Service
- Runtime: Docker
- Root directory: `backend`
- Dockerfile path: `Dockerfile`
- Port: `8080`

Environment variables:

```env
SPRING_DATASOURCE_URL=jdbc:postgresql://...
SPRING_DATASOURCE_USERNAME=...
SPRING_DATASOURCE_PASSWORD=...
JWT_SECRET=very_long_secret
JWT_EXPIRATION_MS=604800000
CORS_ALLOWED_ORIGINS=https://your-vercel-app.vercel.app
JPA_DDL_AUTO=update
```

Use Render PostgreSQL for the database.

## Frontend: Vercel

- Framework: Vite
- Root directory: `frontend`
- Build command: `npm run build`
- Output directory: `dist`

Environment variables:

```env
VITE_API_URL=https://your-render-backend.onrender.com/api
```
