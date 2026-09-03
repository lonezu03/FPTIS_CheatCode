# FitTrack Agent Instructions

## Scope

These instructions apply to everything under `Project/fittrack_ai/`.
Read `docs/CODEX_CONTEXT.md` before starting substantial work and update it
when a material task is completed or handed off to another machine.

## AI assistant handoff links

Use these links when another assistant continues the work. The repository-local
context is the source of truth; public assistant documentation is provided only
for tool-specific conventions.

- [Codex](https://developers.openai.com/codex/): read this file and `docs/CODEX_CONTEXT.md` first.
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code): preserve the same branch, migration, and secret-handling rules.
- [Gemini Code Assist](https://cloud.google.com/gemini/docs/codeassist/overview): use the backend assistant integration only through configured server-side credentials.
- [GitHub Copilot](https://docs.github.com/en/copilot): review the active diff and CI checks before suggesting changes.

No assistant should infer production credentials from these links or commit
secrets. Before editing, check the current task and known issues in
`docs/CODEX_CONTEXT.md`, then update that file when handing work off.

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
- Admin-only account management controls role, active state, module permissions, password reset behavior, and deletion of locked accounts. Deleting a locked account anonymizes its identity while retaining operational history and auditability.
- Registration does not require email verification or OTP; a newly created account can log in immediately. Forgot-password OTPs remain enabled and must be sent only to the email stored on the account; never accept an arbitrary destination email from the client.
- A regular lunch portion selects exactly two dish slots above the `+` separator; both slots may reference the same regular dish. A special/single order selects exactly one dish below it.
- Admin fund adjustments are explicit ledger actions: `ADD_FUND`, `REMOVE_FUND`, `ADD_DEBT`, or `REMOVE_DEBT`. Removing fund/debt cannot exceed the current bucket, and every manual adjustment requires an audit record and note when available.
- Each lunch order records the base menu price plus the selected extra-item prices (35,000 VND by default) against the beneficiary's account. The beneficiary is always the payer for new self or proxy orders: use their available fund first and record any shortfall as their debt. The ordering user is retained only in `orderedBy`; their fund never gates or pays a proxy order. Historical orders keep their stored payer. Insufficient balance or existing debt does not block ordering. External payment/top-up requests change balances only after admin approval.
- Multiple lunch menus may be OPEN for the same date. Each menu is identified by its label/vendor and `createdBy` coordinator; when there are at least two menus, web/mobile must let the user select one, while a single menu keeps the legacy UX. The selected `menuId` scopes the cart and checkout.
- Menu import supports `@DRINKS` or `@EXTRAS` followed by priced lines such as `Trà đào | 45000` or `Trà vải 50000`. Extra IDs may repeat in an order to represent quantity; each repeated line contributes its `unitPrice` to the order total and refund.
- Email notification delivery is opt-in per user via `emailNotificationsEnabled`; menu broadcasts, generic notifications and playbooks must honor it. Password-reset OTP is security-critical and remains independent of this preference.
- User-submitted foods and exercises require admin approval before general use.
- Nutrition days use `UNLOGGED`, `PARTIAL`, `COMPLETE`, or `FASTING`. A day
  containing meals defaults to `PARTIAL` until the user confirms it; only
  `COMPLETE` and `FASTING` days may affect nutrition averages, achievements,
  health scores, or low-intake recommendations. Never interpret missing or
  partial diary data as zero intake.
- Meal quantities accept the legacy serving multiplier and the shared
  `SERVING`, `GRAM`, or `ML` contract. Gram/ml conversion requires the food's
  `servingSizeGrams`; preserve nullable micronutrients so reports can distinguish
  unknown data from a measured zero. Micronutrient warnings require adequate
  data coverage.
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
- When a feature exists on web and mobile, keep API payload names and permission flags identical; do not silently fall back to mock data. Current parity includes email preference, multi-menu/extra lunch checkout, grouped workout history, and notification playbook administration.
- Notification playbooks must support either all active users or an explicit selected-user list. SELECTED requires nonempty IDs for active users only; invalid or locked IDs are rejected. Prefer selected recipients for personal or sensitive wellness messages to avoid notification fatigue. Web and mobile both expose playbook CRUD/edit/toggle/delete.
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


## Todo Planner rules

- Todo P1 supports `startAt`, `dueAt`, `estimatedMinutes`, `category`, `reminderAt`, `recurrenceRule`, `recurrenceInterval`, `daysOfWeek`, and nested `subtasks`. Keep `startAt`, deadline, reminder and duration semantically separate.
- `GET /api/todos` accepts optional `view`, `category`, and `status` filters. `TODAY`, `OVERDUE`, and `UPCOMING` are planning views; status filtering remains independent.
- Recurring tasks must preserve the completed occurrence. When a recurring Todo changes to `DONE`, create the next occurrence in the same `recurringSeriesId` and reset its checklist completion state. Do not reset the original row in place.
- Todo recurrence supports `SCHEDULED_DATE` (fixed cadence) and `COMPLETION_DATE` (next occurrence starts from actual completion), optional end date/max occurrences, yearly cadence and `SKIPPED`. Completing or skipping must create at most one next row, enforced by series + occurrence number.
- Checklist updates are sent as the complete ordered `subtasks` array. The backend replaces children transactionally and cascades deletion with the parent Todo.
- Todo reminders use `Asia/Ho_Chi_Minh`, the shared in-app notification service, a deduplication key based on Todo ID and reminder time, and the same per-user email opt-in behavior as other notifications. Password-reset OTP remains independent.
- The web and Flutter planner must expose the same P1 fields and Vietnamese labels. If Flutter/Dart is unavailable in the sandbox, document that limitation and run `flutter analyze` and `flutter test` on a Flutter workstation before release.
- Schedule owns events/appointments only. `GET /api/schedule/calendar` is the unified read model for Schedule events plus timed Todos; clients must never duplicate a Todo into `schedule_items` merely to display it on a calendar.
