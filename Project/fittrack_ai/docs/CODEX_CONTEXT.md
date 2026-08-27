# FitTrack Current Project State

Last updated: 2026-08-27

## Repository state

- Main repository: `lonezu03/FPTIS_CheatCode`, branch `main`.
- FitTrack root: `Project/fittrack_ai/`.
- Production web: `https://datcom-nhalam.vercel.app`.
- Production backend API:
  `https://https-github-com-lonezu03-fptis.onrender.com/api`.
- Commit `41558501` adds the shared Codex instructions/context. Commit `a91ae9aa`
  contains the mobile UI/permission release and lunch regression test described
  below. Commit `43405745` contains the fitness-history transaction fix; all
  three are on `origin/main`.
- `backend/demo/` is an untracked nested legacy repository and is not the active
  backend. Do not stage it accidentally.

## Completed capabilities

Backend and infrastructure:

- JWT access/refresh authentication, secure web cookies, mobile refresh-token
  responses, token revocation/versioning, and forced first-login password change.
- Registration email verification and forgot-password OTP sent through Brevo REST
  API to the account's registered email.
- Admin account management: role, active state, module permissions, notifications,
  and password reset.
- Flyway-managed PostgreSQL schema (`V1` through `V7`), Aiven SSL deployment,
  request IDs, health check, audit support, and Render Docker deployment.
- Pending change set adds Flyway `V8` to allow multiple lunch portions per
  beneficiary/menu while preserving each portion's own payment and nutrition log.
- New accounts default to lunch-only access (`V6`).
- Lunch menu import, order/cancel, debt accounting, pay-for-another-user flow,
  top-up/debt payment requests, admin approval/rejection, close/reopen, summary,
  notifications, comments/votes, images, and nutrition linkage.
- Workout, workout plan, exercise approval, nutrition/food approval, body metrics,
  health summary, reminders, dashboard, weekly reports, achievements, and Gemini
  assistant endpoints.
- Workout and meal-history DTO mapping now runs inside read-only service
  transactions, so lazy sets/items can be loaded while `open-in-view=false`.

Web:

- Responsive React/Vite application deployed through the Vercel `/api` proxy.
- Vietnamese lunch, fitness, health, reporting, notification, and admin flows.
- SPA refresh rewrite and CSP configured in `frontend/vercel.json`.

Mobile:

- Flutter app covers authentication, persistent secure session, lunch, basic
  fitness/nutrition, health, notifications, administration, and profile/logout.
- Pending mobile source update adds a multi-portion lunch cart and reads the
  plural `myMealOrders` API field with a legacy fallback. Do not build a new APK
  until the user explicitly asks; more mobile updates are expected.
- Custom Android/iOS notification sounds exist for menu import and lunch closing.
- Android release `1.1.2+4` was built against the Render API.
- Phone navigation is limited to five destinations; notification, admin, and
  profile actions are grouped under **Thêm** when needed.
- Dashboard metrics use a two-column phone grid.
- The app explains and requests notification permission, exposes notification
  settings, and uses the native system picker for TXT/CSV menu files. It does not
  request broad storage access.
- API errors preserve `X-Request-Id` for Render log correlation.

## Latest implementation change set

Committed in `a91ae9aa`:

- `mobile/fittrack_mobile/lib/features/home/app_shell.dart`
- `mobile/fittrack_mobile/lib/features/home/dashboard_screen.dart`
- `mobile/fittrack_mobile/lib/features/home/more_screen.dart` (new)
- `mobile/fittrack_mobile/lib/features/admin/admin_screen.dart`
- `mobile/fittrack_mobile/lib/features/profile/profile_screen.dart`
- `mobile/fittrack_mobile/lib/core/network/api_exception.dart`
- `mobile/fittrack_mobile/lib/core/notifications/notification_center.dart`
- `mobile/fittrack_mobile/lib/core/notifications/native_notification_service.dart`
- `mobile/fittrack_mobile/pubspec.yaml` and `pubspec.lock`
- `backend/src/test/java/com/fittrack/lunch/service/LunchServiceIntegrationTest.java`

Fitness-history transaction fix committed in `43405745` and pushed to `main`;
production Render health was confirmed after the push:

- `backend/src/main/java/com/fittrack/workout/service/WorkoutService.java`
- `backend/src/main/java/com/fittrack/nutrition/service/NutritionService.java`
- `backend/src/test/java/com/fittrack/fitness/service/FitnessHistoryIntegrationTest.java`

## Verification completed this session

- Backend: `40` tests passed with Maven, including Flyway/PostgreSQL, the
  empty-menu/new-user lunch regression test, and two fitness-history lazy-loading
  regression tests.
- Mobile: `flutter analyze` returned no issues.
- Mobile: all Flutter widget tests passed.
- Android release APK built successfully:
  `mobile/fittrack_mobile/build/app/outputs/flutter-apk/app-release.apk`.
- APK metadata: version `1.1.2`, version code `4`, size about `53.49 MB`.
- APK SHA-256:
  `B169470E67159011B494B741E10E0E90223A67280CECCD230E249659E6C88ADE`.
- APK manifest contains `android.permission.POST_NOTIFICATIONS`.
- Web checks were not rerun because this change set did not modify web source.
- Remote `main` was confirmed to contain
  `434057458b358e7a9acebb298bc500942246a4a8`.
- On 2026-08-26, production `GET /api/health` returned HTTP `200` with
  application and database status both `UP`; response request ID was
  `aecbaf98-3389-4336-94f9-b53741a7e0e9`.

## Important decisions

- On phones, keep at most five bottom destinations; use **Thêm** for secondary
  destinations. Wide screens may continue using a full navigation rail.
- Ask for notification permission only after an in-app explanation. If permission
  is denied, send the user to OS app-notification settings.
- File import uses the operating system document picker and grants access only to
  the selected file. Do not request whole-device storage permission.
- A production `500` must be diagnosed using its request ID and Render stack trace.
  Request `30264db4-62fc-44d1-9eab-879ade910453` exposed lazy loading in both
  `/workouts/sessions` and `/nutrition/meal-logs`; the fix keeps query and DTO
  mapping in one read-only transaction. `/lunch/today` separately passes
  clean-database integration coverage.
- Production mail remains Brevo REST API because Render Free blocks conventional
  outbound SMTP ports.
- A sleeping Render Free instance must be called by an external uptime/cron
  service; an internal scheduler cannot wake its own stopped process.

## Known issues and risks

- The new Android APK still needs complete hands-on testing on the user's physical
  device with an admin account that has all module permissions.
- The fitness fix is pushed and production is healthy, but the public health
  response does not expose the running commit. Its authenticated workout and
  meal-history paths still need validation on the physical device. If a `500`
  remains, capture the new request ID and search the same ID in Render logs.
- Android background work is scheduled periodically, but the operating system may
  delay it; it is not exact push delivery. True immediate remote notification
  would require FCM/APNs integration.
- iOS has not been built or signed; it requires macOS/Xcode or a remote macOS CI
  service and an Apple signing account.
- `backend/demo/` should be reviewed separately and either intentionally removed
  or ignored; it must not be mixed into normal commits.
- Credentials/API keys shared outside secret managers should be treated as exposed
  and rotated. Keep replacements only in Render, Vercel, Aiven, Gemini/Brevo, and
  local ignored environment files.

## Previous mobile task

Validate the **Luyện tập** tab and remaining permission/file-picker behavior on a
physical device with mobile release `1.1.2+4`.

## Exact next steps

1. In APK `1.1.2+4`, open **Luyện tập** and verify both **Buổi tập** and
   **Nhật ký ăn** load existing records.
2. If the module still fails, record the new `X-Request-Id` shown by the app and
   correlate it with Render logs; the old request ID belongs to the pre-fix build.
3. Continue the remaining notification/file-picker device checks and record the
   accepted mobile version here.

## Current task

Fix the Todo/Schedule production regression and document the handoff for other AI assistants.

## Completed in the current uncommitted change set

- Backend: `POST /lunch/orders/batch`, plural `myMealOrders`, and removal of the
  one-beneficiary/one-menu unique constraint through Flyway `V8`.
- Backend: admin `PUT`/`DELETE /lunch/admin/menus/{id}`. Full replacement or
  deletion is allowed only before any order exists; item edits remain available
  afterward without altering history.
- Web: a clear multi-portion cart, atomic checkout, individual removal, stronger
  sponsored-payment feedback, and admin edit/delete/import-again menu UX.
- Mobile source: matching self-order cart, plural-order display, correct menu
  field names, and clearer selection guidance. No APK build was created.
- Documentation updated in `docs/LUNCH_ORDERING.md` and `docs/API.md`.

## Verification for the current change set

- Backend: `mvnw.cmd test` passed — 42 tests, 0 failures, 2 PostgreSQL
  Testcontainers tests skipped because Docker was unavailable. The new lunch
  integration coverage checks a two-portion batch and draft-menu replacement/
  deletion protection.
- Web: `npm run lint`, `npm test -- --run`, and `npm run build` passed.
- Mobile: `dart analyze lib/features/lunch/lunch_screen.dart` and `flutter test`
  passed. No Android/iOS package build was run.

## Exact next steps

1. Review, stage and commit only this change set; never include `backend/demo/`.
2. Deploy the backend first so Flyway `V8` and the new APIs exist, then deploy
   the Vercel web client.
3. Manually verify: import → edit or delete/reimport before orders; create two
   portions in one cart; edit/cancel only one portion; summarize counts both.
4. Keep the mobile source changes unbuilt until the user requests an APK.

## Hotfix 2026-08-27: Todo/Schedule production regression

- Root cause: the previous change added the V9 database migration and frontend screens but did not include the backend Todo/Schedule entity, DTO, repository, service, or controller classes. This caused the production POST calls to fail with HTTP 500.
- Permission root cause: `AuthResponse` and `AuthService` did not return `todoEnabled` or `scheduleEnabled`; frontend feature gates treated an undefined permission as allowed. The gate is now deny-by-default, and the login/refresh/profile payloads include both flags.
- Backend fix: added `/api/todos` and `/api/schedule` CRUD controllers with DTO validation, user ownership checks, and V9-compatible JPA mappings. `FeatureAccessFilter` blocks both routes when the user lacks the corresponding permission.
- Web fix: removed duplicated Todo/Schedule sidebar entries and preserved one item per module. Direct route access is also protected.
- Verification: Java 21 Maven tests completed without Maven failure; frontend TypeScript and Vite production build passed. Testcontainers integration coverage could not start in the sandbox because Docker was unavailable.
- Deployment note: deploy the backend before or together with the web client so Flyway V9 and the new endpoints are available. After deployment, verify `POST /api/todos` and `POST /api/schedule` with an admin and with a user whose flags are false.

## AI assistant handoff

The canonical assistant instructions are in [`AGENTS.md`](../AGENTS.md). Continue using the same branch and read this context before substantial work. Useful external references for other assistants are [Codex](https://developers.openai.com/codex/), [Claude Code](https://docs.anthropic.com/en/docs/claude-code), [Gemini Code Assist](https://cloud.google.com/gemini/docs/codeassist/overview), and [GitHub Copilot](https://docs.github.com/en/copilot). These links are documentation references only; credentials must remain in Render, Vercel, Aiven, local ignored files, or other secret managers.

Exact next steps for the next assistant:

1. Correlate any remaining production 500 with its `X-Request-Id` in Render logs.
2. Confirm Flyway reports V9 applied and inspect the production database tables `todos` and `schedule_items`.
3. Test permission transitions: disabled user sees neither menu nor page and receives HTTP 403; enabled user can create and delete records; admin can manage permissions.
4. Keep `backend/demo/`, `target/`, `dist/`, `node_modules/`, and credentials out of commits.

## Feature batch 2026-08-27: workout, duplicate lunch, fund controls, mobile parity

- Lunch business rule: a `COMBO` still requires exactly two regular dish slots, but the two `itemIds` may be identical. `SINGLE` remains exactly one special dish. The backend persists repeated IDs as separate order-item rows; web and mobile now expose a clear `+1` action and an `x2` state.
- Admin fund controls: added `POST /api/lunch/admin/funds/adjust` with `ADD_FUND`, `REMOVE_FUND`, `ADD_DEBT`, and `REMOVE_DEBT`. The account service locks the account, validates bucket limits, writes a signed `ADMIN_ADJUSTMENT` ledger transaction, and records audit metadata. The old top-up endpoint remains compatible.
- Web UX: Workout now has summary cards for sessions, sets, volume, and minutes. Admin Lunch funds now use a single flexible adjustment form with member balance/debt context and action-specific safety guidance.
- Mobile parity: lunch duplicate selection uses a list rather than a set; Fitness has workout summary stats; Admin has a Quỹ tab and Todo/Schedule permission toggles; AuthUser persists `todoEnabled` and `scheduleEnabled`; AppShell exposes Lịch & việc only when the corresponding permission or admin role exists; PlannerScreen provides mobile Todo/Schedule listing, create flows, Todo completion, and schedule reminders.
- Documentation: `AGENTS.md` now defines duplicate combo slots, explicit fund actions, and web/mobile contract parity. This file remains the handoff source for Codex, Claude Code, Gemini Code Assist, and GitHub Copilot.

## Verification notes for this batch

- Backend Java 21 compile passed.
- Web TypeScript build and Vite production build passed after the changes.
- Flutter analysis could not be run in the sandbox because neither `flutter` nor `dart` is installed. Before release, run `flutter pub get`, `dart format`, `flutter analyze`, and `flutter test` from `mobile/fittrack_mobile`.
- Generated frontend `node_modules`, `dist`, and temporary package lock files must stay out of the commit.

## Next assistant checks

1. Run Flutter formatting/analyze/tests on a machine with the Flutter SDK.
2. Verify the production DB has the existing V9 Todo/Schedule migration and that the fund adjustment route is deployed with the backend.
3. Test a combo with `itemIds: [sameId, sameId]`, a different two-dish combo, and a single special dish.
4. Test all four fund actions, including attempted over-removal, and verify the ledger balance plus audit event.
5. Test a regular user with each permission combination on web and mobile; forbidden modules must be absent from navigation and return HTTP 403 when called directly.

## Hotfix 2026-08-27: registration, locked-user deletion, and playbook recipients

- Registration no longer requires email verification or an OTP. `AuthService.register` persists `emailVerified=true`, does not create an email-verification token, and returns `verificationRequired=false` / `emailSent=false`. Password-reset OTP remains a separate feature and must not be removed.
- Admin deletion is exposed as `DELETE /api/admin/users/{id}` and is allowed only when the target is inactive. The implementation revokes sessions and anonymizes the account with `deletedAt`, a replacement email, disabled module flags, and a random password, retaining historical lunch/ledger/audit references safely. Admin search excludes anonymized accounts.
- Playbook HTTP 500 root cause: the V9 table and frontend page existed, but the active backend had no playbook entity, DTO, repository, service, or controller. Added `AdminNotificationPlaybookController` at `/api/admin/notification-playbooks`, CRUD service, JPA entity, and scheduler integration.
- Playbook recipient targeting is now explicit through `recipientMode=ALL_ACTIVE|SELECTED` and `recipientUserIds`. Migration V10 adds `recipient_mode` plus `notification_playbook_recipients`; selected playbooks skip inactive recipients. The admin web UI loads users and lets the operator choose a specific recipient list to avoid notification fatigue.
- Migration V11 adds `users.deleted_at`; this is intentionally a new migration because production migrations must not be edited in place.

## Verification for this hotfix

- Backend Java 21 `mvn test` passed in the sandbox. Testcontainers integration tests remain skipped when Docker is unavailable.
- Web TypeScript and Vite production build passed after the notification recipient and admin delete UI changes.
- Flutter SDK/Dart is not installed in the sandbox, so mobile analyze/test remains pending on a machine with Flutter.

## Next assistant checks

1. Deploy backend so Flyway applies V10 and V11 before testing the new web UI.
2. Verify `GET /api/admin/notification-playbooks`, then create one `ALL_ACTIVE` playbook and one `SELECTED` playbook with two user IDs.
3. Verify a scheduled playbook creates at most one notification per user per day and respects `NO_MEAL`, `MEALS_LT`, and `PROTEIN_GT` conditions.
4. Lock a test user and use the admin UI to delete it; confirm it disappears from admin search while historical records remain queryable.
5. Register a new account and confirm the response allows immediate login without email verification. Keep password-reset OTP tests unchanged.

## Android release build 2026-08-28

- Built the current mobile source with `tool/build_android.ps1 -Mode release`.
- APK: `mobile/fittrack_mobile/build/app/outputs/flutter-apk/app-release.apk` (40.4 MB), configured with the production Render API URL through `--dart-define=API_BASE_URL`.
- SHA-256: `0E1C6CD245630E9CF0F011810E12272FC88064F6F8E8092EBFC90BFEAC24F074`.
- SHA-1 sidecar: `42df28734557104ee6e6fd5f0285ad6b64853c9b`.
- Build completed successfully. Flutter reported only the existing `workmanager_android` Kotlin plugin migration warning and an Android SDK XML version warning; no build errors.
- This is a generated artifact and must not be committed. Rebuild after the next mobile source update.


## Feature batch 2026-08-27: email preference, editable playbooks, grouped workout history, multi-menu lunch

- Email delivery now honors `users.email_notifications_enabled` for lunch menu availability emails as well as generic notification delivery. Password-reset OTP remains independent and must continue to be delivered to the account email.
- Web admin notification playbooks support editing, enabled-state preservation, cancel/reset, recipient targeting, and toggle/delete. Backend rejects `SELECTED` playbooks with an empty recipient list or missing/inactive user IDs. Mobile admin now exposes a matching CRUD editor under the fifth admin tab.
- Workout history is grouped by `sessionDate` on web and mobile. Web pagination remains session-based and keeps set-level edit/delete actions; mobile nests sessions and sets under a date expansion card.
- Flyway `V12__multi_lunch_menus_and_priced_extras.sql` drops the deployed one-menu-per-date constraint, adds a date/created-at index, and adds nullable positive `unit_price` to `lunch_menu_items`. The backend supports multiple menus on the same date; `GET /lunch/today` returns `menus` and `requiresMenuSelection`, while `menu` remains populated when exactly one menu exists. Each menu response includes `coordinator` from `createdBy`.
- Lunch import supports `@DRINKS`/`@EXTRAS` sections with `Tên món | 45000` or `Tên món 50000`. `EXTRA` menu items are returned in `extraItems`; repeated `extraItemIds` represent quantity and are added to order totals, fund debit, edit adjustments, refunds, and display text. Legacy regular/special syntax and duplicate combo slots remain compatible.
- Web and mobile lunch flows display a coordinator/menu picker when multiple same-day menus exist, while one-menu UX remains unchanged. Both clients display and submit priced extras.

## Verification for this batch

- Backend `bash mvnw test -q` passed with Java 21. The suite includes parser coverage for priced drink extras; Testcontainers PostgreSQL tests remain skipped when Docker is unavailable.
- Web `tsc -b` and `vite build` passed after the multi-menu, extra pricing, playbook, and grouped workout changes.
- Flutter/Dart is not installed in the sandbox. Before releasing mobile, run `flutter pub get`, `dart format lib`, `flutter analyze`, and `flutter test` from `mobile/fittrack_mobile`. Review the newly added admin playbook tab and lunch multi-menu flow on a physical device.
- Generated `frontend/fittrack-frontend/node_modules`, `dist`, TypeScript build metadata, Maven `target`, and lock artifacts must not be committed.

## Deployment and manual checks

1. Deploy the backend first so Flyway V12 is applied before deploying the web/mobile clients.
2. Import two menus for the same date as different admins, confirm both appear in admin/user views, select each coordinator, and verify checkout uses the selected `menuId`.
3. Import a menu with `@DRINKS`, `Trà đào | 45000`, and `Trà vải 50000`; order one drink twice, verify the total/debit/refund and summary counts.
4. Toggle a user's email preference off and verify menu broadcasts and playbooks still create in-app notifications but do not send email; verify password-reset OTP is unaffected.
5. Create, edit, disable, re-enable, and delete a playbook from both web and mobile; verify selected recipients are required and inactive IDs are rejected.
6. Confirm production logs and `X-Request-Id` for any failed request. Do not stage `backend/demo/` or credentials.
