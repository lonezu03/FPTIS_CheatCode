# FitTrack Current Project State

Last updated: 2026-09-27

## Repository and deployment

- Repository: `lonezu03/FPTIS_CheatCode`, branch `main`.
- FitTrack root: `Project/fittrack_ai/`.
- Current pushed baseline: `ba5cdb11` (`15092026- Lần 3`).
- Active backend: `backend/`; do not use or stage `backend/demo/`.
- Web source: `frontend/fittrack-frontend/`; Vercel build root remains
  `frontend/`.
- Production web: `https://datcom-nhalam.vercel.app`.
- Production API:
  `https://https-github-com-lonezu03-fptis.onrender.com/api`.
- Production schema uses Flyway and `ddl-auto=validate`. The pushed baseline is
  through V25 and the current local Journal work adds V26-V29; production
  `flyway_schema_history` has not been checked during this session.

## Current task: Personal Journal V1/P1/P2

Status: implemented and verified locally; awaiting commit and backend-first deployment.
Backend, web and mobile were completed together. No Lunch business or UI file
was changed.

### Completed in the current local change

- Added independent `journalEnabled` authorization to User, registration/auth,
  profile/dashboard responses, account administration, backend feature filter,
  web routes/sidebar and the permission-aware usage guide. New regular accounts
  still default to Lunch only; admins bypass the flag.
- Added Flyway V26 with 40 curated Vietnamese prompts and owner-scoped prompt
  display, journal entry and reminder setting tables.
- Added `/api/journal` for a stable daily prompt, skip/no-repeat cycles,
  prompt/free-form entry CRUD, private search/filter/pagination, prompt browsing
  and reminder settings. Deleting another user's entry is impossible.
- Added `/api/admin/journal/prompts` management. There is intentionally no admin
  endpoint for reading user entries.
- Added the responsive web Journal page with Today, History and Prompt Library,
  optional title/mood, free-form writing, editing/deleting and reminder time.
- Added backend integration coverage for stable/no-immediate-repeat prompt
  assignment, owner isolation, CRUD and reminder settings.
- Added Flyway V27-V29 for prompt packs, followed packs, owner-scoped tags,
  entry images, private lock sessions and PIN rate limiting. V28 expands the
  curated seed library from 40 base prompts to 320 controlled prompt variants.
- Added prompt depth switching, pack priority, On This Day, month/mood stats,
  advanced history filters, complete prompt-library search/filter/pagination
  and soft-delete while keeping prompts and free-form writing in one entry model.
- Added explicit opt-in personalization from FitTrack activity and AI follow-up.
  Both require the Journal toggle and account-level assistant consent; content
  is not sent to Gemini unless both are enabled.
- Added Markdown and print-to-PDF export. Admin prompt management now includes
  pack create/edit/archive and prompt assignment, without any user-entry read
  endpoint.
- Added a 4-8 digit Journal PIN with hashed, revocable 12-hour unlock sessions,
  five-attempt/15-minute rate limiting and a web unlock header. Flutter stores
  the unlock credential securely and may gate its reuse with device biometrics.
- Added web and Flutter Journal experiences for prompt/free-form writing, mood,
  tags, up to four images, packs, fully paged prompt discovery, reminders, lock
  and private history. Journal notifications deep-link to the module on both
  clients.

### Verification for Journal V1/P1/P2

- Full backend Maven suite passed locally: 97 tests, 0 failures/errors and 2
  PostgreSQL/Testcontainers release suites skipped because Docker was not
  available. The final Journal-focused suite passed 5/5 after adding coverage
  for the five-failure PIN lockout; the release JAR packaged successfully.
- Web ESLint passed; Vitest passed 5 files / 10 tests; the TypeScript/Vite
  production build passed with 2,619 modules transformed.
- Flutter tests passed 3/3. The new Journal screen passes targeted analysis with
  no issue; full `flutter analyze` reports 36 pre-existing `info`-level notices
  elsewhere and no warning/error. Android/iOS release signing was not performed.
- Production PostgreSQL execution of V26-V29 remains a Render deployment task.

### Deployment and smoke test

1. Deploy Render backend first and confirm Flyway V26, V27, V28 and V29 succeed.
2. As admin, grant `journalEnabled` to a test user; create/edit/archive a prompt
   pack and assign a prompt to it.
3. As that user, answer/skip/switch depth, write a free-form entry with tag,
   mood and image, follow a pack, then verify filters, On This Day and exports.
4. Turn on assistant consent plus each Journal AI toggle separately and confirm
   no AI call is allowed until both consents are active.
5. Set a PIN, confirm other Journal calls return 423 without an unlock header,
   unlock successfully, and verify repeated wrong attempts are rate-limited.
6. Confirm another user and admin cannot query that user's entry by ID.
7. Deploy Vercel web after backend checks; build/release mobile only after the
   deployed API smoke test succeeds.

## Previous task: Schedule completion, workout-plan editing and catalog enrichment

Status: implemented and verified locally; awaiting review, commit and deployment.
The user explicitly requested web/backend only, and no mobile file changed.

### Completed in the current local change

- Schedule DAY/WEEK/MONTH/LIST views now let users complete an OPEN or
  IN_PROGRESS Todo directly. The UI calls the existing Todo transition API and
  invalidates calendar, Todo and Dashboard caches; recurring Todo behavior
  remains owned by `TodoService`.
- Added owner-scoped `PUT /api/workout-plans/{id}`. Updating a plan replaces its
  nested days/exercises transactionally through orphan removal while preserving
  the plan identity and creation date. Only active, approved exercises can be
  saved, and create/update now share structural validation.
- The workout-plan web editor supports load/edit/cancel/save with gym-oriented
  defaults and keeps create/delete/generate-session behavior unchanged.
- Reworked `ExerciseSeeder` into an idempotent upsert and added 49 commercial
  gym exercises focused on machines, Smith machine, barbells, dumbbells,
  adjustable benches and cables, with Vietnamese technique/safety descriptions.
  Existing user-submitted exercises are not overwritten.
- Enriched 23 common seeded foods with fiber, sugar, sodium, potassium, calcium,
  iron, vitamin C, water and gram-equivalent serving data. Values are explicitly
  marked ESTIMATED and do not replace existing non-null or verified values.
- Per the user's follow-up, no image was added or changed. Both seeders preserve
  `imageUrl` so the admin can curate exercise and food images manually.
- No Flyway migration was needed because the existing schema already contains
  all fields; the idempotent seeders update Aiven data on backend startup.

### Finance transaction hotfix already in the pushed baseline

- Replaced the static JPQL transaction search containing nullable parameters
  with a dynamic JPA Specification. Empty account, category, type and text
  filters are now omitted from SQL instead of being bound as untyped nulls,
  avoiding PostgreSQL parameter type-inference failures.
- Preserved owner scoping, inclusive date selection, destination-account
  matching for transfers, text/type/category filters, pagination and descending
  transaction ordering.
- Added `FinanceTransactionQueryIntegrationTest` to execute the no-filter
  monthly request and a combined-filter request through real Hibernate/JPA.
- No schema migration, web contract, Lunch file or mobile file changed.

### Completed in the pushed Finance baseline

- Added independent `financeEnabled` authorization to User, auth/profile/
  dashboard responses, admin account management, backend feature filtering,
  web route/sidebar and the main Dashboard Finance card. Admin bypasses the
  module flag; new regular accounts still default to Lunch only.
- Added Flyway V25 owner-scoped tables for accounts, categories, transactions,
  monthly budgets and recurring rules.
- Added `/api/finance` account/category/transaction/budget/recurring/dashboard/
  monthly-report APIs and the initial responsive Vietnamese Finance page.
- Added positive-amount `EXPENSE`/`INCOME`/`TRANSFER` accounting. Opening balance
  is not income; transfers affect two account balances and are excluded from
  reports; `VOID` transactions remain stored and are excluded from totals.
- Added five expense natures: `FIXED_MANDATORY`, `ESSENTIAL_VARIABLE`,
  `TRUE_EXPENSE`, `SAVING`, `DISCRETIONARY`. The selected nature is stored on
  each expense so it can override the category default.
- Added budget projection and deduplicated 80%/100% notifications. Recurring
  rules notify but never auto-post; the owner explicitly confirms the real
  transaction.

### Completed in the pushed Finance follow-up

- Rebuilt the Finance web page with typed API payloads and create/edit flows for
  transactions, money accounts, categories, budgets and recurring rules.
- Added transaction filters for text, type, account and category, paginated
  history, visible VOID state, clearer totals and responsive onboarding.
- Added descriptions for all five expense natures and lets users override the
  category default on both ordinary and recurring expenses.
- Added recurring confirmation labels appropriate to expense, income and
  transfer, plus a “Nhắc lại ngày mai” action; archive confirmations preserve
  history.
- Added recent-category quick actions, default Vietnamese subcategories and
  Budget/Upcoming sections to the Finance overview.
- Added category parent selection and backend validation that a parent is
  active, belongs to the same owner, is not itself and has the same income/
  expense kind.
- Archiving an account now also stops active recurring rules that use it.
  Archived transactions cannot be revived by editing; repeated void is
  idempotent; archived categories cannot receive new budgets.
- Corrected web end-of-month calculation so UTC conversion cannot shift the
  requested date in positive time zones.
- Added a permission-aware Finance section to the interactive usage guide.
- Updated `AGENTS.md`, `docs/API.md` and `CHANGELOG.md` with Finance contracts.
- No Lunch business/UI file and no mobile file was changed in this follow-up.

### Verification

- Full backend Maven suite passed: 93 tests, 0 failures/errors; the two
  PostgreSQL/Testcontainers release suites were skipped because Docker was not
  available to this test run.
- The backend release JAR also packaged successfully with
  `mvnw -DskipTests package`.
- The final Finance service suite passed 8 tests, including default Vietnamese
  subcategory seeding and recurring snooze; the earlier combined Finance/
  permission/admin run passed 14 tests.
- Web ESLint passed; Vitest passed 5 files / 10 tests; TypeScript/Vite production
  build passed with 2616 modules transformed.
- PostgreSQL execution of V25 remains a CI/Render task if it has not already
  deployed; local compile does not execute Flyway against PostgreSQL.

### Deployment order and smoke tests

1. Commit/push only the FitTrack files from this task; unrelated deletions above
   the FitTrack root belong to the user and must remain untouched.
2. Deploy Render backend first. Startup runs the idempotent catalog seeders; no
   Flyway version is added by this change.
3. Deploy Vercel web, then complete a Todo from each calendar presentation used
   in production and verify recurring Todos create at most one next occurrence.
4. Create a plan, edit its name/days/exercises, reload, and generate a workout
   from an updated day.
5. Verify gym exercises and food micronutrients are present; add images manually
   through the existing admin catalog UI when ready.

## Stable platform summary

- Auth uses JWT access/refresh with secure HttpOnly web cookies and persistent
  mobile secure storage. Registration is immediately usable and defaults to
  Lunch-only permissions; forgot-password OTP is sent only to the stored email.
- Lunch supports multi-menu ordering, multiple portions, proxy beneficiaries,
  debt/fund ledger, payment approval, priced extras, review/comment/images and
  Nutrition sync. Do not modify its business rules during Finance work.
- Fitness includes exercise approval, searchable muscle/equipment picker,
  workout plans, live grouped workouts and deterministic Workout Intelligence.
- Nutrition/health use trusted diary states and nullable micronutrients; Planner
  uses Todo recurrence plus the unified calendar; Quotes use owner-scoped daily
  no-repeat rotation.
- Web/mobile shared request tracking blocks duplicate concurrent writes. Backend
  authorization remains the security boundary for every module.

## Known follow-up items

- Mobile Finance UI/parity is intentionally deferred until the user explicitly
  reopens app work.
- Savings goals, CSV import/export, receipt OCR, bank synchronization, AI
  categorization and Lunch-ledger integration are outside Finance V1.
- Production Flyway version and authenticated Finance smoke tests must be
  confirmed after deployment; do not infer them from a successful source build.
- Exercise and food images are intentionally left for manual admin curation;
  the catalog seeders preserve existing `imageUrl` values.
