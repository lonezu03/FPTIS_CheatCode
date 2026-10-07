# FitTrack Current Project State

Last updated: 2026-10-07

## Latest handoff: Nutrition web render crash (2026-10-07)

The Nutrition page crashed after successful HTTP 200 responses because the web
expected `recent`/`collections`, but `/api/nutrition/convenience` returns
`recentFoods`/`savedMeals`. Web types and rendering now match the backend DTO;
saved-meal display uses per-serving totals. The save-collection request now
sends `servingAmount`/`servingUnit`, and successful saves refresh quick meals.
Changed only `frontend/fittrack-frontend/src/api/nutrition.api.ts`,
`src/pages/NutritionPage.tsx`, and added `src/pages/NutritionPage.test.tsx`.
Verification: web lint, all 11 Vitest tests, and production build passed.
Deploy web only, then smoke-test `/nutrition` with an empty and a populated
quick-meal list plus the save/reuse flow. No backend or mobile deployment needed.

## Current task: new-account permissions and planner performance (2026-10-07)

Status: implemented locally; deploy backend before web/mobile clients. Existing
accounts retain their saved permissions. New regular users get Fitness, Health,
Chatbot, Todo, Schedule, Quote, Finance and Journal by default; Lunch is off.
The role remains USER, so admin operations are still restricted.

- Registration, entity null fallback and Flyway V30 use the same defaults.
- Quote seed already exists at authenticated `POST /api/demo/seed`: it creates
  eight idempotent personal quotes plus workout demo data on demand. It does
  not seed every new account automatically.
- Calendar queries now prune Todo/event rows in the database by owner and
  requested time window; the recurring-event expansion skips elapsed daily or
  weekly periods. Web fetches editable events only for its visible range.
- Schedule reminder scanning excludes old one-off events. V30 adds targeted
  PostgreSQL planner indexes. Existing ID types were not changed: broad PK/FK
  migration carries high risk and no evidence yet points to IDs as the bottleneck.
- Mobile initially requests 30 days back and 60 days ahead, loads Todo and
  Calendar concurrently, offers 60-day extensions, and only uses the legacy
  `/schedule` fallback when `/schedule/calendar` is absent (404/405).

Verification: backend suite 100 tests, 0 failures/errors, 2 skipped; includes
an H2 integration test for bounded calendar queries. Web lint/build and 10
Vitest tests passed. Flutter tests passed 10/10; targeted analysis has no
errors/warnings and retains 18 existing info-level notices. PostgreSQL
migration/index verification still needs a Docker-enabled or staging PostgreSQL
run; Docker was unavailable on this workstation. No APK was built for this task.

Next: deploy backend (Flyway V30), then web; build/deploy mobile separately.
After deployment, register a disposable account and verify permissions, load
Schedule on web/app with long history, and compare Render request durations.
For a production performance diagnosis collect `EXPLAIN (ANALYZE, BUFFERS)`
on a representative planner query without exposing user data or credentials.

## Current task: mobile notification inbox and phone notification recovery

Status: inbox works on device; Android system notification icon corrected in
release `1.2.4+10`. Requires a device/account smoke test. The production
endpoint responds with HTTP 401 without a token, confirming the route is
reachable, but a signed-in response cannot be checked without the user's
session.

### Completed

- Foreground notification inbox now fetches `/api/notifications` immediately
  after authentication. Native plugin initialization and Workmanager scheduling
  run separately, so delays or failures there no longer block the in-app bell.
- API data is published to the inbox before attempting Android/iOS native
  delivery. Native permission, plugin or local storage errors cannot erase a
  successful backend response.
- Native delivery history records only IDs actually displayed. If more than
  three unread notifications arrive together, the remainder stay eligible for
  subsequent syncs. The native test reports failure if permission is revoked
  before Android accepts the notification.
- Added a visible bell and unread count to the app top bar. Opening it requests
  a fresh sync. The Notification screen keeps permission/test controls visible
  even when the API fails and shows its error, retry action and last successful
  sync time. Returning to the foreground also refreshes the inbox immediately.
- Device screenshot confirmed the in-app inbox works but native notification
  initialization failed with `PlatformException(invalid_icon)`. The vector
  `ic_stat_fittrack` existed in source but was removed by Android resource
  shrinking because Flutter references it only by a runtime string.
- Added the drawable to `res/raw/keep.xml` and made the Android build script
  assert that `aapt dump resources` finds it in every APK. Raised Android app
  version to `1.2.4+10`.

### Verification

- Flutter tests: 10/10 passed, including inbox startup, error recovery and
  native delivery failure isolation.
- Flutter analysis: no errors or warnings; 42 existing info-level notices.
- Android release APK built successfully; `aapt` confirms version code 10,
  version name 1.2.4 and packaged drawable `ic_stat_fittrack`.
- APK: `mobile/fittrack_mobile/build/app/outputs/flutter-apk/app-release.apk`
  (SHA-256
  `0284043F8CBD3ECF0418C6BAABB12C0CC5A80A5773BEF3A7EF5BD1C0BBC25AED`).

### Device follow-up

1. Install the APK over the existing app and open the new top-bar bell. If its
   API fails, capture the displayed message and request ID for Render logs.
2. On the Notification screen, grant Android permission and press `Gửi thử`;
   check the phone's notification shade and app notification settings/channels.
3. Trigger a new backend notification for that account and confirm the bell
   and phone notification. Foreground checks run every minute; background
   Workmanager checks are subject to Android scheduling. Instant delivery with
   the app force-stopped still needs FCM and Firebase credentials.

## Current task: web visual enrichment

Status: implemented and verified locally; pending Vercel deployment and browser
smoke testing on desktop/mobile widths.

### Completed

- Added a responsive, code-native FitTrack wellness illustration to the
  Dashboard hero. It combines training, health and progress motifs without any
  external image URL or additional raster download.
- Reworked the shared web empty state with reusable vector artwork and contextual
  variants for workouts, food/nutrition, body progress and notifications.
- Applied the contextual visuals to Exercise, Workout Plan, Workout, Food,
  Nutrition, Body Tracking, Health and Weekly Report empty states.
- Kept all visuals decorative for screen readers, responsive and compatible with
  reduced-motion preferences. No backend, mobile, schema or Lunch flow changed.

### Verification

- Web ESLint passed.
- Vitest passed 5 files / 10 tests.
- Production Vite build passed with 2,621 modules transformed.

## Current task: demo quotes/workouts and Android system notifications

Status: implemented, verified and release APK built; pending backend/web deploy
and physical-device smoke testing.

### Completed

- Extended the authenticated demo seed flow with eight idempotent Vietnamese
  favorite quotes and four recent gym workout sessions (push, pull, legs and
  upper-body technique). Existing workout dates and duplicate quote content are
  preserved, so running the seed action again does not duplicate those samples.
- Added `quotesCreated` to the demo seed response and showed the quote/workout
  counts in the web Dashboard success message. No schema migration was needed.
- Fixed mobile native-notification delivery history: notifications are no longer
  recorded as delivered while Android/iOS notification permission is disabled.
  Granting permission clears the old delivery cache and immediately refreshes
  unread backend notifications.
- The app rechecks permission after returning from system settings and the
  Notification screen now provides a `Gửi thử` action that posts a real native
  notification to the phone's system tray.
- Raised the mobile release to `1.2.2+8`.

### Verification

- Backend clean test: 98 passed, 0 failed/errors, 2 skipped.
- Web ESLint passed; Vitest passed 5 files / 10 tests; production build passed
  with 2,619 modules transformed.
- Flutter analysis has no error/warning and retains 42 existing info notices;
  Flutter tests passed 7/7.
- Android release build passed. `aapt` confirms version code 8/name 1.2.2 and
  `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`, and `WAKE_LOCK` permissions.
- APK: `mobile/fittrack_mobile/build/app/outputs/flutter-apk/app-release.apk`
  (61.45 MiB, SHA-256
  `5470F9A80E890192B3D710F72F3A12D3FA8F8D9B227F6FCB639DC429DCD939A3`).

### Remaining device/deployment checks

1. Deploy the backend and web, then use the admin Dashboard demo-data action and
   confirm the returned counts plus owner-scoped quote/workout views.
2. Install the APK, open Notifications, grant permission and press `Gửi thử`;
   verify the item appears in the Android notification shade.
3. Current delivery uses foreground polling and Workmanager background polling
   (minimum 15-minute cadence and subject to Android scheduling). Message-like
   instant delivery while the app is force-stopped still requires a future FCM
   integration and Firebase deployment credentials.

## Current task: mobile API errors and native notifications

Status: implemented, tested and release APK built; requires an Android device
smoke test for the OS permission dialog and background delivery.

### Completed

- Centralized mobile API error parsing so backend JSON, Dio responses,
  validation maps and common HTTP statuses become concise Vietnamese messages
  instead of raw response objects. Production `X-Request-Id` remains visible for
  Render log correlation without exposing request headers or response dumps.
- Added explicit notification-permission UI both after login and on the mobile
  Notification screen. Granting permission immediately posts a native
  confirmation notification so the user can verify system-tray delivery.
- Created Android high-priority channels for reminders and general FitTrack
  updates, added a valid monochrome notification status icon, and routed health,
  Todo, Schedule and Journal reminder types through the reminder channel.
- Existing foreground polling and 15-minute Workmanager background sync now
  surface new backend notifications through Android/iOS native notifications;
  the in-app bell remains the notification history, not the only delivery UI.
- Raised the mobile release version to `1.2.1+7` so the APK can update the prior
  installation cleanly. No backend, web or Lunch source was changed.

### Verification

- `flutter analyze`: no error/warning; 42 existing info-level notices remain.
- `flutter test`: 7/7 passed, including API payload/status/error parsing tests.
- Android release build passed. `aapt` confirms version code 7 and Android
  permissions `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED` and `WAKE_LOCK`.
- APK: `mobile/fittrack_mobile/build/app/outputs/flutter-apk/app-release.apk`
  (61.43 MiB, SHA-256
  `7FBD1BDEC600193D24AB2B8918FACEB4D8C4A014A3FA06118F63932BBCC0DB3A`).

### Device smoke test

1. Install over the previous APK, sign in and accept the FitTrack rationale and
   Android notification permission dialog.
2. Confirm the immediate `Đã bật thông báo FitTrack` system notification.
3. Create a health/Todo/Schedule reminder a few minutes ahead, background the
   app and confirm its backend notification reaches the phone. Android may defer
   the periodic worker; exact real-time delivery while force-stopped requires a
   future push provider such as FCM.

## Current task: shared branding and mobile Finance/Planner stabilization

Status: implemented and verified locally; awaiting deployment/install smoke test.

### Completed

- Reused the approved square calligraphy/red-seal app icon as the web brand
  image on desktop/mobile login, sidebar branding, browser favicon and Apple
  touch icon. The optimized public asset is
  `frontend/fittrack-frontend/public/branding/fittrack-logo.png`.
- Fixed mobile Finance requests to send the selected month as the backend
  `LocalDate` contract (`yyyy-MM-01`) for dashboard, budgets and budget writes;
  the former `yyyy-MM` value was rejected before controller execution.
- Fixed mobile Planner calendar range from 395 to 360 days, below the backend
  370-day limit, so unified calendar data no longer falls back unnecessarily.
- Fixed a Planner runtime `RangeError`: the schedule list declared one item too
  many and indexed beyond the returned data whenever the list was nonempty.
- Reworked mobile navigation to render at most five destinations on every
  screen size. When more permissions are enabled, three primary modules plus
  Dashboard and `Thêm` are shown; `Thêm` now lists every allowed module so no
  permission becomes unreachable.
- No backend schema/API, Lunch business logic or Lunch UI source changed.

### Verification

- Web ESLint passed, Vitest passed 5 files / 10 tests and production Vite build
  passed with 2,619 modules transformed.
- Flutter tests passed 3/3. Flutter analysis has no error/warning and retains 44
  existing info-level style/deprecation notices.
- Android release build passed. The new APK is
  `mobile/fittrack_mobile/build/app/outputs/flutter-apk/app-release.apk`
  (61.31 MiB, SHA-256
  `BA38FC87E7C5DDB57B4C6B531DF8D35161D3CC92917BDD3FC6B106B6D9253BDB`).

### Deployment / smoke test

1. Deploy Vercel for the shared logo and favicon.
2. Install the next APK, use a full-permission account and confirm navigation
   never exceeds five items; open hidden modules from `Thêm`.
3. Open Finance for the current and adjacent months and create/edit a budget.
4. Open Planner with empty and nonempty schedule data, then complete a Todo from
   the unified calendar and verify no `RangeError` or 400 range error occurs.

## Current task: mobile module permissions, Finance/Assistant parity and branding

Status: implemented and release APK built locally; backend deployment still
controls whether newly added permission fields/APIs are available in production.

### Completed

- Added `financeEnabled` to the persisted Flutter auth user contract so refresh,
  relaunch and profile refresh retain the same permission value as web/backend.
- Added permission-aware native mobile entry points for Personal Finance and
  FitTrack PT. Phone navigation places them under `Thêm`; wide layouts expose
  them as navigation destinations. Users without the corresponding flag do not
  see them; admins retain the documented bypass.
- Added native Finance dashboard, monthly transaction create/edit/void,
  account/category create/edit/archive, monthly budget create/edit/delete and
  recurring confirm/snooze/archive flows using the real `/api/finance` APIs.
- Added native Assistant consent, chat, proposed-action confirmation, history
  deletion and privacy flows using `/api/assistant`; no model secret is stored
  in the app.
- Added Finance and Chatbot switches to mobile account administration and added
  all active module flags to the mobile profile/permission-aware guide.
- Replaced Android and iOS launcher icons with a square, safe-area version of
  the user-provided black-ink calligraphy and red seal artwork. The source master
  is `mobile/fittrack_mobile/assets/branding/app_icon_master.png` and launcher
  assets are generated by `flutter_launcher_icons`.
- Raised Android `minSdk` from 24 to 26 because `health` 13.x declares API 26;
  this fixes the release manifest merge without unsafe library overrides.
- No backend, web or Lunch business/UI source was changed.

### Verification

- `flutter_launcher_icons` generated Android adaptive/legacy and iOS icons.
- `flutter analyze` completed with no error or warning; 44 info-level style/
  deprecation notices remain across the existing project.
- `flutter test` passed 3/3.
- Production release build succeeded against the configured Render API. Output:
  `mobile/fittrack_mobile/build/app/outputs/flutter-apk/app-release.apk`
  (61.2 MB).

### Follow-up smoke test

1. Install on Android 8.0+ and verify cold launch, persisted login and the new
   launcher icon under both circular and rounded-square launchers.
2. Grant/revoke Finance and Chatbot from an admin account, refresh the user's
   profile/relogin, and confirm both modules appear/disappear on phone and tablet.
3. Exercise Finance CRUD on a test account and confirm balances/reports match
   web; consent to Assistant, chat, reject then confirm a proposed action.
4. Confirm the deployed backend includes the latest auth/profile permission
   payloads before diagnosing a missing module as a mobile defect.

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
