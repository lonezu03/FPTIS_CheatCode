# FitTrack Current Project State

Last updated: 2026-08-30

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

## Current task: Nutrition diary P0/P1

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
  and switches to full-width actions/single-column controls on narrow screens.

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

## Verification for the current task

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

## Important decisions

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

## Known issues and risks

- V15 must be deployed with the backend before deploying the new web/mobile
  clients; otherwise the new diary endpoints/columns do not exist in production.
- Food gram/ml accuracy depends on `servingSizeGrams`; old foods without that
  metadata should use `SERVING` until reviewed.
- Physical-device UX and authenticated production checks remain pending.
- Full Flutter analysis has pre-existing info-level lints outside this change set.
- `backend/demo/`, generated directories, credentials and local SDK files must
  remain outside commits.

## Exact next steps

1. Review the Nutrition diff and commit only the files listed by `git status` for
   this change set; do not include generated files or `backend/demo/`.
2. Deploy backend first and confirm Flyway V15, then deploy web. Verify
   `/api/nutrition/diary`, day status, water logs, health summary and weekly report
   with an authenticated user.
3. Test on a physical phone: multi-food meal, gram conversion, water quick-add,
   COMPLETE/PARTIAL/FASTING transitions and lunch-linked read-only entries.
4. Start the next Nutrition increment with Saved Meals + recent/favorites, then
   recipes and actual-consumption handling for lunch before barcode/voice/AI work.
