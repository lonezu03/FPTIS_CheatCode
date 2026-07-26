# Deploy Option 1: Render + Vercel

## Backend: Render

- Service type: Web Service
- Runtime: Docker
- Root directory: `backend`
- Dockerfile path: `Dockerfile`
- Port: `8080`

Environment variables:

```env
SPRING_DATASOURCE_URL=jdbc:postgresql://<AIVEN_HOST>:<AIVEN_PORT>/<AIVEN_DATABASE>?sslmode=require
SPRING_DATASOURCE_USERNAME=avnadmin
SPRING_DATASOURCE_PASSWORD=<set-in-render-dashboard>
JWT_SECRET=<set-in-render-dashboard>
JWT_EXPIRATION_MS=604800000
CORS_ALLOWED_ORIGINS=https://fptis-cheat-code.vercel.app
JPA_DDL_AUTO=update
JPA_SHOW_SQL=false
```

Use Aiven PostgreSQL for the database. Copy the host, port, database name, username, and password from the Aiven service Overview page.

## Frontend: Vercel

- Framework: Vite
- Root directory: `frontend`
- Build command: `npm run build`
- Output directory: `dist`

Environment variables:

```env
VITE_API_URL=https://your-render-service.onrender.com/api
```

Backend production:

```txt
BACKEND_URL=https://your-render-service.onrender.com
API_BASE_URL=https://your-render-service.onrender.com/api
Swagger=https://your-render-service.onrender.com/swagger-ui/index.html
```
