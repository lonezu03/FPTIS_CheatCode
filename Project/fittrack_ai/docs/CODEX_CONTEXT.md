# FitTrack Current Project State

Last updated: 2026-08-31

## Repository and deployment

- Repository: `lonezu03/FPTIS_CheatCode`, branch `main`.
- FitTrack root: `Project/fittrack_ai/`.
- Current remote HEAD before the Nutrition change set: `f8301d2a`.
- Production web: `https://datcom-nhalam.vercel.app`.
- Production backend API:
  `https://https-github-com-lonezu03-fptis.onrender.com/api`.
- Active backend is `backend/`; never use or stage the legacy `backend/demo/`.
- Production schema is Flyway-managed with `ddl-auto=validate`. The current
  uncommitted Nutrition batch adds migration V15.

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

## Workout plan web/API fix (2026-08-31)

- Fixed `GET /api/workout-plans`, `/page` and plan detail mapping with
  `spring.jpa.open-in-view=false`: `WorkoutPlanService` now keeps a read-only
  transaction open while mapping lazy plan days, exercises and exercise details.
- Workout plan mapping tolerates legacy null day/exercise order values and now
  returns exercise equipment, description and image URL in addition to its name
  and muscle group.
- Web plan creation shows the selected exercise's muscle group, equipment,
  description/instructions and image. Saved plan cards expose the same context.
- Added `WorkoutPlanServiceIntegrationTest` covering nested list, paginated list
  and detail reads with open-in-view disabled.
- Verification: targeted backend integration test passed; targeted frontend
  ESLint passed; frontend TypeScript/Vite production build passed (2604 modules).
- Deploy the backend before the web so the additive workout-plan response fields
  are available. No database migration is required.

## Current task: Todo recurrence and unified calendar

Status: implemented locally, verified, not committed or deployed yet.

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
