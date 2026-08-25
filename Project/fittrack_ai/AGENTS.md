# FitTrack Agent Instructions

## Scope

These instructions apply to everything under `Project/fittrack_ai/`.
Read `docs/CODEX_CONTEXT.md` before starting substantial work and update it
when a material task is completed or handed off to another machine.

## Project

FitTrack is a company lunch-ordering, fitness, nutrition, and health-management
platform with web and mobile clients sharing one Spring Boot API.

## Active source locations

- Backend: `backend/src/` with build file `backend/pom.xml`.
- Web source: `frontend/fittrack-frontend/src/`.
- Vercel build root: `frontend/`; `frontend/build-vercel.mjs` builds the nested
  web source and copies its output to `frontend/dist/`.
- Mobile source: `mobile/fittrack_mobile/lib/`.
- Database migrations: `backend/src/main/resources/db/migration/`.
- Operational and API documentation: `docs/`.

`backend/demo/` is an untracked nested/legacy copy of the backend. Do not edit,
build, stage, delete, or use it as the active backend unless the user explicitly
requests that directory.

## Stack

Backend:

- Java 21, Spring Boot 4, Spring Security, JWT access/refresh authentication.
- Spring Data JPA/Hibernate, PostgreSQL, Flyway, Maven, Testcontainers.
- Modular monolith: controller -> service -> repository -> PostgreSQL, with DTOs
  and mappers at the API boundary.

Web:

- React 19, TypeScript, Vite, React Router, TanStack Query, Zustand.
- Tailwind CSS, Recharts, React Hook Form, Zod.

Mobile:

- Flutter/Dart, Dio, Provider, secure storage, local notifications, Workmanager.
- Android release builds use `mobile/fittrack_mobile/tool/build_android.ps1`.

Deployment:

- Backend: Render Docker service.
- Web: Vercel using same-origin `/api` proxy rewrites.
- Database: Aiven PostgreSQL with SSL.
- Email: Brevo REST API in production; SMTP is only a local/paid-host option.
- Media: Cloudinary when configured.
- Assistant: Gemini is called by the backend only.

## Stable business rules

- A newly registered account starts active for the lunch module only. Fitness,
  health, and chatbot permissions remain disabled until an admin grants them.
- Admin-only account management controls role, active state, module permissions,
  and password reset behavior.
- Registration requires email verification in production. Forgot-password OTPs
  must be sent only to the email stored on the account; never accept an arbitrary
  destination email from the client.
- A regular lunch portion selects exactly two dishes above the `+` separator; a
  special/single order selects exactly one dish below it.
- Each lunch order records the configured price as debt (35,000 VND by default).
  Insufficient balance does not block ordering. External payment/top-up requests
  change balances only after admin approval.
- User-submitted foods and exercises require admin approval before general use.
- The web uses secure HttpOnly auth cookies through the Vercel `/api` proxy. The
  mobile app persists refresh credentials in Keystore/Keychain until logout.

## Engineering rules

- Do not expose JPA entities from controllers. Use request/response DTOs.
- Keep authorization checks on the backend; hiding a frontend route is not an
  authorization boundary.
- Preserve API contracts unless the requested change explicitly requires a
  coordinated backend, web, and mobile migration.
- Change production schema only through a new Flyway migration. Never edit an
  already deployed migration. Production uses `ddl-auto=validate`.
- Never commit API keys, JWT secrets, database passwords, SMTP/Brevo credentials,
  Cloudinary secrets, tokens, certificates, or real `.env` files. Do not print
  secrets in tests or logs. Browser-visible `VITE_*` values are public.
- Do not introduce production service URLs into application source. Use runtime
  configuration or deployment configuration. Mobile URLs are supplied with
  `--dart-define=API_BASE_URL=...`.
- Preserve unrelated user changes in a dirty worktree. Stage and commit only the
  files belonging to the current task.
- Do not edit generated/dependency directories such as `target/`, `build/`,
  `dist/`, `node_modules/`, `.pub-cache/`, or `.local-android-sdk/`.
- Keep user-facing web/mobile text in Vietnamese unless the user asks otherwise.
- For production HTTP failures, retain and report `X-Request-Id`, then correlate
  it with Render logs before guessing at the cause.

## Verification

Run checks proportional to the changed module:

```powershell
# Backend
cd backend
.\mvnw.cmd test

# Web
cd frontend\fittrack-frontend
npm run lint
npm test
npm run build

# Mobile
cd mobile\fittrack_mobile
flutter analyze
flutter test
powershell.exe -ExecutionPolicy Bypass -File .\tool\build_android.ps1
```

If the Flutter SDK is not on `PATH`, the build script uses the local SDK path
configured for this workstation. Do not commit workstation-specific SDK files.

## Deployment references

- Production web: `https://datcom-nhalam.vercel.app`
- Production backend: `https://https-github-com-lonezu03-fptis.onrender.com`
- Production API: `https://https-github-com-lonezu03-fptis.onrender.com/api`
- Local backend: `http://localhost:8081/api`
- Docker backend host port: `http://localhost:8082/api`

Deployment secrets live in Render/Vercel/Aiven dashboards, never in this file.
See `docs/DEPLOYMENT.md`, `docs/deploy-render-vercel.md`, and
`docs/OPERATIONS.md` before changing production configuration.

## Handoff protocol

Before ending a substantial work session, keep `docs/CODEX_CONTEXT.md` concise
and update:

- completed work;
- files/modules changed;
- important technical decisions;
- verification performed;
- known issues and unfinished work;
- exact next steps for the next machine/session.

Do not store chat transcripts, credentials, access tokens, or personal secrets in
the context file.
