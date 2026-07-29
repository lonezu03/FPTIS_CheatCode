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
JWT_EXPIRATION_MS=604800000
CORS_ALLOWED_ORIGINS=https://fptis-cheat-code.vercel.app
JPA_DDL_AUTO=update
JPA_SHOW_SQL=false
OPENAI_API_KEY=<new-key-set-only-in-render-dashboard>
OPENAI_MODEL=gpt-5.6-terra
OPENAI_REQUESTS_PER_MINUTE=6
KEEP_ALIVE_ENABLED=true
KEEP_ALIVE_INTERVAL_MS=600000
```

Use Aiven PostgreSQL for the database. Copy the host, port, database name, username, and password from the Aiven service Overview page.

Set Render's Health Check Path to `/api/health`. Render automatically provides
`RENDER_EXTERNAL_URL`, which the optional keep-alive scheduler uses to call the
health endpoint every 10 minutes. Do not put `OPENAI_API_KEY` in `render.yaml`,
Git, Vercel, or any `VITE_` environment variable.

## Frontend: Vercel

- Framework: Vite
- Root directory: `Project/fittrack_ai/frontend`
- Build command: `npm run build`
- Output directory: `dist`

Environment variables:

```env
VITE_API_URL=https://your-render-service.onrender.com/api
VITE_KEEP_ALIVE_MINUTES=10
```

Backend production:

```txt
BACKEND_URL=https://your-render-service.onrender.com
API_BASE_URL=https://your-render-service.onrender.com/api
Swagger=https://your-render-service.onrender.com/swagger-ui/index.html
```
