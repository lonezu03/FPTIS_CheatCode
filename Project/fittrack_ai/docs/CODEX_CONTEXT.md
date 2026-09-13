# FitTrack Current Project State

Last updated: 2026-09-13

## Repository and deployment

- Repository: `lonezu03/FPTIS_CheatCode`, branch `main`.
- FitTrack root: `Project/fittrack_ai/`.
- Source baseline before the release-hardening batch: `0a02f7b2`.
- Production web: `https://datcom-nhalam.vercel.app`.
- Production backend API:
  `https://https-github-com-lonezu03-fptis.onrender.com/api`.
- Active backend is `backend/`; never use or stage the legacy `backend/demo/`.
- Production schema is Flyway-managed with `ddl-auto=validate`. Active source
  migrations are committed through V19; the actual production Flyway version
  still requires a read-only `flyway_schema_history` check after deployment.

## Stable completed platform

- Spring Boot API with JWT access/refresh auth, secure web cookies, mobile secure
  session persistence, request IDs, PostgreSQL/Flyway and Render deployment.
- Account registration defaults to lunch-only access. Admin manages active state,
  role, module permissions, password resets and locked-account retention.
- Forgot-password OTP is sent only to the email stored on the account. Production
  email uses Brevo REST API.
- Lunch supports multi-menu ordering, duplicate regular dishes, priced extras,
  multiple portions, cancellation/refunds, debt/fund ledger, external payment
  approval, menu notifications, votes/comments, images and nutrition sync.
- Fitness supports approved exercises, workout plans, live multi-exercise workout,
  ordered sets, set types, previous performance, rest timer and workout history.
- Planner P1 supports filtered Todos, independent start/deadline/reminder fields,
  subtasks and recurring occurrences; notification playbooks support all active
  users or selected active users.
- React web and Flutter mobile share backend contracts and Vietnamese labels.

## Current task: Workout Intelligence V19 (2026-09-13)

Status: implemented and verified locally; backend/web deployment and the next
explicitly requested mobile release build are pending.

### Completed

- Added deterministic progressive-overload guidance from the authenticated
  user's latest completed working sets. The engine supports target set/rep/RIR
  ranges and recommends increasing weight, building reps, or holding/reducing
  load with a Vietnamese explanation.
- Added derived personal bests and new-record detection for heaviest weight,
  reps at a weight, Epley estimated 1RM and per-exercise session volume. Warm-up
  sets are excluded; saving a session returns its new PRs without a breaking
  request change.
- Added weekly completed working-set count and load volume grouped by muscle,
  including comparison with the prior week.
- Added V19 owner-scoped exercise preferences (`FAVORITE`, `NORMAL`, `LESS`,
  `EXCLUDED`) and ranked same-muscle alternatives. Only active, approved
  exercises are eligible and excluded choices are never recommended.
- Web live workout shows prior performance, progression/apply action, PR cards,
  weekly volume, preference control and equivalent replacement. Flutter exposes
  the same workflow, potential-PR feedback when completing a set and a confirmed
  PR result dialog after saving.
- Updated API/changelog/README and persistent project rules. No Lunch module
  source was changed and no APK was built.

### Verification

- Backend full Maven suite: 75 tests, 0 failures/errors, with the two PostgreSQL/
  Testcontainers release suites skipped because Docker was unavailable. A final
  targeted run passed all 4 Workout Intelligence tests covering progression,
  weekly-volume warm-up exclusion/comparison, preference-aware alternative
  ranking and PR detection that ignores warm-ups.
- Web targeted ESLint and TypeScript project build passed. Flutter formatted
  both changed files and targeted analysis passed with no issues.
- PostgreSQL execution of V19 remains pending until CI/Render runs Flyway.

### Deployment / exact next steps

1. Commit this V19 batch, then deploy backend first so Flyway creates
   `exercise_preferences`; confirm Render starts with `ddl-auto=validate`.
2. Deploy web and smoke-test `/api/workouts/intelligence`, `/weekly-volume`,
   preference update, alternatives and session save/PR using a Fitness-enabled
   non-admin account. Retain `X-Request-Id` on any failure.
3. Include Flutter changes only in the next explicitly requested APK build and
   test apply-suggestion/replacement/PR on a physical phone.

## Previously completed: Release baseline, health and documentation (2026-09-13)

Status: deployed from commit `f4f165e520cc2277041342cf6c365cc7e54b421f`;
public production health/proxy checks passed. Authenticated smoke tests and the
read-only production Flyway query remain pending.

### Completed

- Added explicit public liveness/readiness probes. Liveness contains only
  application state/ping; readiness contains application state and database.
- Disabled Spring SMTP health by default because production uses Brevo REST.
  This prevents an unused SMTP connection from marking the full Actuator health
  DOWN; SMTP deployments may opt in with `MAIL_HEALTH_ENABLED=true`.
- `GET /api/health` now returns the Maven version and Render/Git source commit.
  Render should use `/actuator/health/readiness` as its health-check path.
- Added integration coverage for unauthenticated `/api/health`, aggregate
  health, liveness and readiness.
- Updated the PostgreSQL release tests to require exactly all source migrations
  through V18 and assert the Quote schema/permission.
- CI now parses Surefire reports and fails if either PostgreSQL/Testcontainers
  release suite is missing, skipped or failed. Backend reports are uploaded on
  every CI outcome.
- Reconciled README/backend/frontend/architecture/API/deployment/operations
  documentation with the active source. Added `CHANGELOG.md`, security baseline,
  release checklist and system-design summary.
- Removed the unused production `registration-requires-email` setting. Current
  stable behavior remains immediate login after registration; forgot-password
  OTP still requires configured email.
- No Lunch business code, frontend/mobile feature code or database migration was
  changed.

### Verification

- `HealthEndpointIntegrationTest`: 2 tests passed, covering application health,
  build identity, aggregate Actuator health and both public probes.
- Full backend suite: 72 tests, 0 failures/errors, 2 PostgreSQL/Testcontainers
  tests skipped because Docker Desktop is not running on this workstation.
- The new CI report gate was run locally and correctly failed on those two
  skipped suites. GitHub's Docker-enabled runner must execute them successfully.
- `git diff --check` passed. No production database connection variables were
  available locally, so production `flyway_schema_history` was not queried.

### Deployment / exact next steps

1. Confirm the Render dashboard Health Check Path is
   `/actuator/health/readiness` and CI's PostgreSQL suites had zero skips.
2. Run the read-only Flyway query in `docs/RELEASE_CHECKLIST.md`; expected source
   baseline is V18.
3. Complete authenticated smoke tests for lunch-only user, fully permitted user
   and admin.
4. Create a `fittrack-vYYYY.MM.DD.N` tag only after production
   verification. Branch protection/required CI checks remain a GitHub setting.
5. Next approved hardening batch: BOLA regression tests and backend financial
   idempotency, isolated from unrelated Lunch UI/business changes.

### Production verification (2026-09-13)

- Render liveness, readiness and aggregate Actuator health returned HTTP 200
  with `UP`; the previous aggregate 503 is resolved.
- Direct and Vercel-proxied `/api/health` returned database `UP`, version
  `0.0.1-SNAPSHOT` and commit `f4f165e520cc2277041342cf6c365cc7e54b421f`,
  matching repository HEAD.
- CORS preflight from `https://datcom-nhalam.vercel.app` to Render login returned
  HTTP 200 with the expected origin, credentials, methods and request headers.
- Direct and proxied protected Workout Plan requests without a session returned
  HTTP 401, while `/actuator/info` remained admin-protected with HTTP 401.
- Direct refresh of Vercel `/workout-plans` returned HTTP 200 `index.html`, so
  the SPA rewrite remains healthy.

## Previously completed: Todo carry-over in unified calendar (2026-09-12)

Status: implemented locally and verified; backend/web deployment and the next
mobile release build are pending.

### Completed

- `GET /api/schedule/calendar` now emits virtual daily occurrences for each
  timed `OPEN`/`IN_PROGRESS` Todo from its original scheduled date through the
  current Vietnam date. It does not mutate Todo dates or create Schedule rows.
- Completing an overdue Todo stops carry-over on `completedAt`. Its calendar
  occurrences retain `status=DONE`; web Day/Week/Month/List views and the Flutter
  schedule list render the title struck through with completed styling.
- Skipped, cancelled and archived Todos do not carry forward. Todos without
  `startAt` or `dueAt` remain absent from the time-based calendar.
- Web Todo mutations invalidate both Todo and calendar caches, so completion
  styling appears immediately when navigating to the calendar.
- Updated the persistent Planner rule and API documentation. No migration or
  stored API payload change is required.

### Verification

- Backend full Maven suite: 70 tests executed, 68 passed, 0 failures, with 2
  PostgreSQL/Testcontainers tests skipped because Docker was unavailable. New coverage
  verifies daily carry-over, unchanged stored dates, completion-day inclusion
  and no occurrences after completion.
- Targeted web ESLint passed, full Vitest passed 5 files / 10 tests, and the
  TypeScript/Vite production build passed with 2613 modules transformed.
- Targeted Flutter analysis has no errors/warnings; only 16 existing info-level
  Planner lints remain. Full Flutter tests passed 3 tests.

### Deployment / next step

1. Deploy backend first, then web. No Flyway migration is needed.
2. Test an overdue task across Day/Week/Month, complete it, and confirm immediate
   strikethrough plus no carry-over on the following day.
3. Include Flutter changes in the next explicitly requested APK build.

## Previously completed: Shared API loading and duplicate-submit guard (2026-09-09)

Status: implemented locally and verified; web deployment and the next mobile
release build are pending.

### Completed

- Web and Flutter now track all requests at their shared HTTP client, so API
  coverage does not depend on each page remembering to implement loading.
- Reads remain parallel/non-blocking and show a thin progress indicator. While
  a `POST`, `PUT`, `PATCH` or `DELETE` is pending, a global Vietnamese loading
  overlay blocks additional user interaction.
- An identical concurrent write (method + endpoint + query + payload) is
  rejected before reaching the backend. The guard is released on success,
  network/API error and auth-refresh completion; retrying after completion is
  allowed.
- Duplicate-submit errors retain a clear user-facing message on both clients.
  No backend endpoint, schema, API contract or Lunch module file changed.

### Verification

- Web full ESLint passed; Vitest passed 5 files / 10 tests, including three new
  activity/duplicate-guard tests; TypeScript/Vite production build passed with
  2613 modules transformed.
- Flutter targeted analysis passed with no issues; full analysis has no errors
  or warnings and only 26 pre-existing info-level lints. Full Flutter tests
  passed 4 tests, including two new activity/duplicate-guard tests.
- No APK was built. Flutter checks used a process-local Git safe-directory
  setting for `E:/tools/flutter`; no global workstation configuration changed.

### Deployment / next step

1. Review and commit this client-only batch, then deploy web normally.
2. Include the Flutter changes in the next requested APK and verify the overlay
   on a physical phone during success, API failure and a slow Render cold start.
3. For financial operations requiring cross-device idempotency, add a dedicated
   backend idempotency key in a separate change; this client guard intentionally
   prevents same-client double submit and does not replace server transactions.

## Previously completed: Personal Quote Library, permission and daily resurfacing (2026-09-06)

Status: implemented locally and verified; backend/web deployment and mobile
release build are pending.

### Completed

- Added Flyway `V17__favorite_quotes.sql` with separate personal quotes, tags,
  many-to-many tag links and daily-display history. Quote metadata keeps author,
  source type/title/URL/location, personal note, language, archive state and the
  independent `includeInDaily` preference.
- Added authenticated, owner-scoped `/api/quotes` CRUD, archive/restore,
  duplicate-check, paginated search/filter, detail/history and `/api/quote-tags`.
  Normalized SHA-256 content hashes warn about case/whitespace/Unicode duplicates
  while an explicit `allowDuplicate=true` preserves the user's **Vẫn lưu** choice.
- `GET /api/quotes/today` uses a pessimistic user lock plus database uniqueness
  constraints so concurrent web/mobile requests return one stable quote per
  Vietnam date. Eligible quotes are sampled without replacement; the cycle only
  advances after the user's active daily pool is exhausted. Empty pools return
  HTTP 200 with `quote: null`.
- Added the responsive web **Kho câu nói** route/sidebar entry with card layout,
  quick and expanded form, tags, search/filter/pagination, duplicate warning,
  copy, detail, archive/restore/delete and display history. Dashboard has an
  isolated **Câu nói hôm nay** card; quote API failure cannot fail the dashboard.
- Added Flutter parity: Quote Library CRUD/search/filter/load-more, source/note/
  tags, duplicate confirmation, archive/restore/delete, detail/history and copy.
  The phone entry is under **Thêm**, wide layouts have a direct destination, and
  Dashboard shows the same server-selected daily quote.
- Added independent `quoteEnabled` authorization through Flyway V18, User,
  login/refresh/profile/dashboard responses and admin account management. New
  and existing regular accounts default to disabled; admins bypass the flag.
- Backend rejects both `/api/quotes` and `/api/quote-tags` with HTTP 403 without
  Quote access. Revoking permission preserves all owner-scoped quote data.
- Web and Flutter hide the Quote navigation/library, permission-aware guide and
  Dashboard daily quote when access is absent. Both admin clients can grant or
  revoke the permission; Flutter also shows it in the profile permission chips.
- No file under backend/web/mobile Lunch modules was edited. Existing Lunch APIs,
  state, payment rules and UI remain unchanged.

### Verification

- Backend full Maven suite passed: 68 tests, 0 failures, 2 PostgreSQL/
  Testcontainers tests skipped because Docker was unavailable. The 3 new quote
  integration tests cover metadata/search/duplicate handling, no-repeat daily
  rotation, same-day stability, archive replacement, ownership and deletion.
  Added filter tests cover denial, grant and admin bypass; admin/auth tests cover
  permission grant and the disabled registration default.
- Web ESLint passed, Vitest passed 4 files / 7 tests, and the production
  TypeScript/Vite build passed with 2611 modules transformed.
- Flutter targeted analysis reports only existing info-level findings and no
  warning/error in the changed permission integration. Widget tests passed.
- No APK was built. PostgreSQL execution of V17 remains pending because Docker/
  Testcontainers was unavailable; its SQL uses the same varchar UUID/FK and
  Flyway conventions as the deployed schema.

### Deployment / next step

1. Review and commit this Quote batch only. Deploy backend first so Flyway V17
   and V18 create the schema and permission column, then deploy web.
2. Test create/edit/duplicate/archive, the daily card and cycle behavior with an
   authenticated account on production. Retain `X-Request-Id` for any failure.
3. Include Flutter changes in the next explicitly requested APK build and test
   the bottom sheets on a narrow physical Android device.
4. Deferred by scope: daily Quote notifications, themed rotation, CSV/OCR/import,
   image sharing and AI tagging/explanation.

## Previously completed: Permission-aware user guide (2026-09-05)

Status: implemented locally and verified; deployment/app release build are pending.

### Completed

- Added an interactive Vietnamese user-guide popup to web and Flutter instead
  of a downloadable document. It is available from the persistent question-mark
  action; Flutter also exposes it in **Thêm -> Hướng dẫn sử dụng**.
- Guide categories are filtered from the authenticated account permissions.
  Users only see the Lunch, Todo, Schedule, Fitness and Health instructions they
  may use; admins additionally see account permission, lunch coordination and
  notification administration guidance. General navigation, notifications and
  profile guidance remain available to everyone.
- Permission filtering now uses the latest `/users/me` profile on web. Flutter
  refreshes that profile whenever the guide opens (with the last securely stored
  profile as an offline fallback) and now persists `chatbotEnabled` alongside
  the other module flags. Both clients show a clear **Được dùng / Chưa cấp**
  permission summary; admin is explicitly labeled as having full access.
- Each module contains a short step-by-step flow with a UI illustration, labeled
  arrow, highlighted circular target, progress indicator, previous/next actions
  and explicit action text. Web steps can open the related authorized route.
- Lunch guidance now has dedicated steps and clearer mock screens for menu and
  recipient selection, choosing dishes, the multi-portion cart, reviewing a
  consumed dish, fund top-up/debt payment through QR/admin approval, and order/
  wallet history. Highlight ellipse size/position and arrow endpoint are now
  percentage-based per visual instead of one fixed bottom-right overlay.
- No backend endpoint, authorization rule, API payload or database migration was
  added. Backend permission checks remain the security boundary.

### Verification

- Web full ESLint passed; Vitest passed 3 files / 4 tests, including explicit
  lunch-only versus admin guide-access assertions; TypeScript/Vite
  production build passed with 2605 modules transformed.
- Flutter targeted analysis for the guide and its two integration points passed
  with no issues; Flutter widget tests passed.
- No APK was built because this request did not ask for a release artifact.

### Deployment / next step

1. Review and commit the five guide/integration files plus this context update.
2. Deploy the web normally. Include the Flutter changes in the next requested
   APK build and verify the bottom sheet on a physical narrow-screen device.

## Workout-plan exercise picker (2026-09-05)

Status: implemented locally and verified; web deployment is pending.

- Replaced the native exercise `<select>` in web Workout Plan creation with a
  searchable dialog. The selected exercise remains visible as a compact field,
  while the dialog shows image, name, equipment and technical description.
- The same shared picker now replaces the exercise `<select>` inside free/live
  Workout mode. Changing an exercise preserves that draft block's sets, weight,
  reps, RIR, completion state and rest duration; previous-performance loading
  follows the newly selected exercise ID.
- Existing `muscleGroup` is intentionally used as the parent classification;
  no duplicate `parent` database/API field was added. Users can combine the
  parent muscle-group facet, equipment facet and free-text search.
- Search is accent/case insensitive, token based and covers name, muscle group,
  equipment and description. Results are grouped under their parent muscle
  group, include counts and expose clear-filter/empty states.
- Verification: targeted ESLint passed; search/filter Vitest passed 3 tests and
  the full web suite passed 4 files / 7 tests; TypeScript/Vite production build
  passed again after the free-workout integration with 2608 modules transformed. No
  backend, Flyway or mobile contract change was required.

## Fitness access request (2026-09-02)

- Lunch-only non-admin accounts now see Vũ's contact email and a
  **Yêu cầu mở Rèn luyện** action on the web dashboard.
- `POST /api/notifications/access-requests/fitness` derives the requester's
  identity from authentication and notifies every active admin. Each admin gets
  at most one request per user per day; repeated clicks return an idempotent
  success message instead of creating notification spam.
- Admin notification clicks route to Account Management so permissions can be
  reviewed. The endpoint is documented in `docs/API.md`; no migration is needed.
- Verification: `LunchNotificationServiceTest` passed all 3 tests; targeted web
  ESLint passed; the production TypeScript/Vite build passed (2604 modules).
- Deploy backend before web. Flutter does not yet expose this request action.

## Workout plan web/API fix (2026-08-31)

- Fixed `GET /api/workout-plans`, `/page` and plan detail mapping with
  `spring.jpa.open-in-view=false`: `WorkoutPlanService` now keeps a read-only
  transaction open while mapping lazy plan days, exercises and exercise details.
- Workout plan mapping tolerates legacy null day/exercise order values and now
  returns exercise equipment, description and image URL in addition to its name
  and muscle group.
- Web plan creation shows the selected exercise's muscle group, equipment,
  description/instructions and a persistent image preview. Exercises without an
  image show an explicit placeholder and a hint to update the Exercise Library;
  saved plan cards expose the same exercise context.
- Added `WorkoutPlanServiceIntegrationTest` covering nested list, paginated list
  and detail reads with open-in-view disabled.
- Verification: targeted backend integration test passed; targeted frontend
  ESLint passed; frontend TypeScript/Vite production build passed (2604 modules).
- Deploy the backend before the web so the additive workout-plan response fields
  are available. No database migration is required.

## Previously completed locally: Proxy lunch orders charge the beneficiary (2026-09-03)

Status: implemented locally; backend/web deployment and mobile release build are pending.

### Completed

- New self and proxy lunch orders now always assign `payer = beneficiary`.
  `orderedBy` records only who submitted the order. A proxy order never checks,
  debits, or adds debt to the ordering user's account.
- The beneficiary's positive fund is consumed first. Any shortfall is recorded
  as beneficiary debt, so insufficient fund and existing debt do not block
  either self-ordering or ordering for a colleague.
- Cancelling a new proxy order refunds the beneficiary account, clearing debt
  first and crediting any remainder to fund. Historical orders retain and
  refund their stored payer so the existing ledger is not rewritten.
- Increasing an order price through extras debits its stored payer and may add
  debt. Both the beneficiary and original orderer remain authorized to edit the
  order before cutoff; the editor does not become the payer.
- Removed the web's sponsored-cart affordability guard and replaced it with
  clear guidance that the recipient owns the charge. The order card distinguishes
  the new beneficiary-funded rule from historical proxy orders.
- Corrected repeated priced-extra calculation in the current-portion summary and
  avoided duplicate React keys when the same regular dish is selected twice.
- Switching between multiple menus now clears the draft selection/cart instead
  of retaining item IDs from the previous menu. Debt guidance now displays the
  actual portion total including extras and uses a positive debt amount.
- `GET /api/lunch/people` now returns only active users who currently have Lunch
  access (active admins remain eligible). The backend rejects sponsored orders
  for locked users or users whose Lunch permission was revoked.
- The web profile query now refreshes on focus and once per minute, reducing the
  temporary mismatch after an admin changes module permissions. Backend access
  was already immediate because `JwtAuthFilter` reloads the user and
  `FeatureAccessFilter` checks database-backed flags on every request.
- Flutter lunch is now aligned with the web/backend proxy-order flow: it loads
  eligible recipients from `/api/lunch/people`, sends `beneficiaryUserId` for
  each cart portion, explains that the recipient owns the fund/debt, and shows
  active portions that the current user placed for colleagues.
- The Android build helper now rejects an incomplete Flutter SDK up front with
  a specific error instead of failing later inside `flutter_tools`.

### Verification

- Backend full Maven suite: 61 tests passed, 0 failed, 2 PostgreSQL/Testcontainers
  tests skipped because Docker was unavailable.
- Lunch integration suite: 13 tests passed, including proxy ordering with an
  underfunded beneficiary, refund to that beneficiary, extra-price debt,
  repeated debt and revoked Lunch permission.
- Web Vitest: 2 files / 2 tests passed; ESLint passed; production TypeScript/Vite
  build passed (2604 modules transformed).
- The complete mobile source passed `dart analyze` with no errors or warnings;
  26 existing info-level style/deprecation findings remain. `flutter test`
  could not start because the workstation's temporary Flutter SDK is missing
  `packages/flutter_tools/pubspec.yaml`; restore/reinstall that SDK before the
  release build and run the Flutter test suite.
- No schema migration or API payload change is required. Deploy backend first,
  then web, and test with the affected account after a hard refresh. No mobile
  APK was built for this change.

## Previously completed: Todo recurrence and unified calendar

Status: implemented and verified; production deployment was not rechecked in the
current session.

### Completed

- Added Flyway `V16__planner_recurrence_and_calendar.sql` with recurrence basis,
  end/max limits, occurrence numbering, completion/skip timestamps and extended
  Schedule recurrence fields. A partial unique index prevents duplicate rows for
  the same recurring occurrence.
- Todo supports fixed schedule (`SCHEDULED_DATE`) or next date based on actual
  completion (`COMPLETION_DATE`), yearly cadence, optional end/max occurrence,
  explicit complete/skip endpoints and checklist reset on the next occurrence.
- Schedule reminder dispatch is now real, minute-based and deduplicated through
  the shared notification service.
- Added `GET /api/schedule/calendar?from&to`, a unified read model containing
  Schedule events plus timed Todos when the user has Todo permission. It expands
  daily/weekly/monthly/yearly event occurrences without duplicating Todo records.
- Rebuilt web Schedule with Ngày/Tuần/Tháng/Danh sách views, navigation, unified
  source badges and full event create/edit/delete form. Rebuilt Todo recurrence
  UX and added deterministic Vietnamese quick-add parsing for common phrases.
- Flutter now uses the unified calendar feed and supports recurrence basis,
  end/max limits, yearly cadence and “Bỏ qua lần này”. No APK was built.
- `docs/API.md` and `AGENTS.md` contain the new contracts and invariants.
- Mobile hotfix after device testing:
  - Todo and Schedule now load independently, so one failed endpoint no longer
    hides both tabs behind the same error screen.
  - Schedule falls back to legacy `GET /schedule` when a deployed backend does
    not yet expose `/schedule/calendar`; completing Todo similarly falls back to
    the legacy PATCH contract on HTTP 404/405.
  - Notification playbooks load independently from the admin-user selector,
    validate `HH:mm` before submission, safely format legacy time values and use
    a compact action menu to avoid mobile `ListTile.trailing` overflow.
  - Backend playbook DTO now returns HTTP 400 validation for invalid time instead
    of allowing `LocalTime.parse` to surface as HTTP 500; nullable legacy
    recipient collections serialize as an empty list.

### Verification

- Backend full suite passed before the last Schedule reminder/test additions:
  52 tests, 0 failures; Flyway applied all 16 migrations successfully.
- Targeted `TodoServiceTest,ScheduleServiceTest` passed after the final backend
  changes, including completion-based cadence, skip cadence and calendar merge.
- Web targeted ESLint passed and the production TypeScript/Vite build passed
  (2604 modules transformed).
- Flutter targeted analysis reported no errors/warnings, only 17 existing
  info-level style/deprecation findings; Flutter widget tests passed.
- Hotfix verification: backend compilation passed; Flutter analysis of Planner
  and Admin reported no errors/warnings (only existing info-level lints), and
  Flutter widget tests passed.

### Deployment order and next steps

1. Review and commit the Planner batch. Deploy backend first so Flyway V16 runs,
   then deploy web; old clients remain compatible with optional fields.
2. Verify complete/skip idempotency, completion-based chores, week/month calendar,
   event editing and in-app Schedule reminders using an authenticated account.
3. Test the Flutter Planner on a physical device. Build an APK only when the user
   explicitly asks after remaining app updates are finished.
4. A later P2 can add multiple reminder offsets, snooze and per-occurrence event
   exceptions; V16 intentionally keeps one reminder per Todo/event.

## Previously completed: Nutrition diary P0/P1

Status: implemented locally, verified, not committed or deployed yet.

### Backend completed

- Added Flyway `V15__nutrition_diary_quality_and_water.sql`:
  - food serving-size and source/verification metadata;
  - meal item serving amount/unit and gram equivalent;
  - `nutrition_day_states` and `water_logs`.
- Added day quality states `UNLOGGED`, `PARTIAL`, `COMPLETE`, `FASTING`.
  Days containing meals default to `PARTIAL`; only `COMPLETE`/`FASTING` are
  trusted for nutrition averages, achievements, health scoring and low-intake
  recommendations. Missing/partial days are no longer interpreted as zero intake.
- Added `GET /api/nutrition/diary`, day-status update and water-log CRUD endpoints.
- Meal items accept legacy `quantity` plus `servingAmount` and
  `servingUnit=SERVING|GRAM|ML`. Editing or deleting a meal invalidates the day's
  prior completion; moving a meal updates both the old and new day.
- Preserved unknown micronutrients as `null` rather than zero. Health summary now
  reports nutrient coverage and suppresses deficiency warnings below 80% coverage.
- Weekly reports, recommendations and health summary return data confidence,
  complete/partial/unlogged counts and provisional/insufficient-data states.
- Lunch-created meal logs write the same serving/source fields and mark the day
  partial. Achievement streaks use only trusted days.

### Web completed

- Rebuilt **Nhật ký ăn uống** around date navigation and four groups: bữa sáng,
  trưa, tối and phụ.
- Supports adding multiple foods in one dialog, serving/gram/ml quantities,
  source quality hints, per-meal macros and edit/delete for manual meals.
- Food management now accepts a serving gram/ml conversion, source type/name and
  admin verification flag. Unknown micronutrients stay blank/null instead of
  being forced to zero; the table shows source trust and the edit form is Vietnamese.
- Shows consumed/target/remaining macros, separate water quick-add, and explicit
  complete/partial/fasting confirmation. Lunch-linked meals remain read-only.
- Health and weekly report screens show confidence, data coverage, provisional
  scoring and exclude partial/unlogged dates from trusted charts.
- Nutrition meal-entry dialog responsive hotfix (2026-08-31): removed horizontal
  overflow from long food names, uses auto-fit result columns, separates the
  searchable food list from selected-item editing, keeps actions in a fixed footer,
  and switches to full-width actions on narrow screens. It explicitly overrides
  the shared dialog's `sm:max-w-md`/`sm:p-6`; each selected food now uses a stable
  two-row layout so browser zoom and narrow modal widths cannot overlap labels.

### Flutter completed

- Replaced the basic meal-history tab with the shared daily Nutrition diary:
  date navigation, status, macro remaining, water quick-add, grouped meals and
  multi-food entry using serving/gram/ml.
- Health screen shows provisional score, complete/partial/unlogged counts,
  confidence and micronutrient coverage/status.

### Documentation and persistent rules

- `docs/API.md` documents the new diary, day-status, water and serving contracts.
- `AGENTS.md` records the trusted-day and nullable micronutrient rules so another
  assistant does not reintroduce the zero-intake bug.

### Nutrition verification

- Backend full run before the final variable-scope correction: 52 tests executed;
  all existing 51 tests passed, and the new move-date test exposed that local
  compile mistake. After correction, a clean targeted
  `FitnessHistoryIntegrationTest` run passed all 4 tests, including gram
  conversion, trusted-day transition and old/new date invalidation.
- `HealthSummaryServiceTest` passed after adding the regression assertion that
  missing water entries return `NO_DATA` instead of a low-intake warning.
- Flyway PostgreSQL integration applied all 15 migrations successfully.
- Web targeted ESLint passed for the changed Food/Nutrition/Health/Report/API files.
- Web Vitest suite passed: 2 files, 2 tests.
- Web TypeScript and Vite production build passed (2604 modules transformed).
- The meal-entry responsive hotfix also passed targeted ESLint and a fresh Vite
  production build (2604 modules transformed).
- Flutter formatting changed no files; targeted analysis for changed files passed.
- Flutter widget tests passed. Full-project analysis still reports only existing
  info-level findings in unrelated Admin/Lunch/Planner files.
- No APK was built, by design.

### Nutrition decisions

- Data completeness is user-confirmed, not inferred merely from the existence of
  one meal. `FASTING` is valid only without meals; `COMPLETE` requires a meal.
- Fat overage is displayed neutrally; missing micronutrient values are unknown,
  not zero; deficiency advice requires adequate coverage.
- Existing clients may continue sending `quantity`. New clients should send
  `servingAmount` and `servingUnit`.
- Saved meals, favorites/recent shortcuts, recipes, barcode scanning, voice input,
  meal planning and AI food recognition are separate P1/P2 increments rather than
  being mixed into this schema/UI batch.
- Do not build a release APK until the user explicitly asks after remaining app
  updates are complete.

### Nutrition known issues and risks

- V15 must be deployed with the backend before deploying the new web/mobile
  clients; otherwise the new diary endpoints/columns do not exist in production.
- Food gram/ml accuracy depends on `servingSizeGrams`; old foods without that
  metadata should use `SERVING` until reviewed.
- Physical-device UX and authenticated production checks remain pending.
- Full Flutter analysis has pre-existing info-level lints outside this change set.
- `backend/demo/`, generated directories, credentials and local SDK files must
  remain outside commits.

### Deferred Nutrition next steps

1. Review the Nutrition diff and commit only the files listed by `git status` for
   this change set; do not include generated files or `backend/demo/`.
2. Deploy backend first and confirm Flyway V15, then deploy web. Verify
   `/api/nutrition/diary`, day status, water logs, health summary and weekly report
   with an authenticated user.
3. Test on a physical phone: multi-food meal, gram conversion, water quick-add,
   COMPLETE/PARTIAL/FASTING transitions and lunch-linked read-only entries.
4. Start the next Nutrition increment with Saved Meals + recent/favorites, then
   recipes and actual-consumption handling for lunch before barcode/voice/AI work.
