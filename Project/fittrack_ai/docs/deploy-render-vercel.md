# Deploy Option 1: Render + Vercel

## Backend: Render

- Service type: Web Service
- Runtime: Docker
- Root directory: `backend`
- Dockerfile path: `Dockerfile`
- Port: `8080`

Environment variables:

```env
SPRING_DATASOURCE_URL=jdbc:postgresql://dpg-d8eqo6l7vvec73du09vg-a:5432/fittrack_db_b1ri
SPRING_DATASOURCE_USERNAME=fittrack_user
SPRING_DATASOURCE_PASSWORD=<set-in-render-dashboard>
JWT_SECRET=<set-in-render-dashboard>
JWT_EXPIRATION_MS=604800000
CORS_ALLOWED_ORIGINS=https://fptis-cheat-code.vercel.app
JPA_DDL_AUTO=update
JPA_SHOW_SQL=false
```

Use Render PostgreSQL for the database.

## Frontend: Vercel

- Framework: Vite
- Root directory: `frontend`
- Build command: `npm run build`
- Output directory: `dist`

Environment variables:

```env
VITE_API_URL=https://https-github-com-lonezu03-fptis.onrender.com/api
```

Backend production:

```txt
BACKEND_URL=https://https-github-com-lonezu03-fptis.onrender.com
API_BASE_URL=https://https-github-com-lonezu03-fptis.onrender.com/api
Swagger=https://https-github-com-lonezu03-fptis.onrender.com/swagger-ui/index.html
```
