# FitTrack Current Project State

Last updated: 2026-08-25

## Repository state

- Main repository: `lonezu03/FPTIS_CheatCode`, branch `main`.
- FitTrack root: `Project/fittrack_ai/`.
- Production web: `https://datcom-nhalam.vercel.app`.
- Production backend API:
  `https://https-github-com-lonezu03-fptis.onrender.com/api`.
- Commit `41558501` adds the shared Codex instructions/context. Commit `a91ae9aa`
  contains the mobile UI/permission release and lunch regression test described
  below; both are on `origin/main`.
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
- New accounts default to lunch-only access (`V6`).
- Lunch menu import, order/cancel, debt accounting, pay-for-another-user flow,
  top-up/debt payment requests, admin approval/rejection, close/reopen, summary,
  notifications, comments/votes, images, and nutrition linkage.
- Workout, workout plan, exercise approval, nutrition/food approval, body metrics,
  health summary, reminders, dashboard, weekly reports, achievements, and Gemini
  assistant endpoints.

Web:

- Responsive React/Vite application deployed through the Vercel `/api` proxy.
- Vietnamese lunch, fitness, health, reporting, notification, and admin flows.
- SPA refresh rewrite and CSP configured in `frontend/vercel.json`.

Mobile:

- Flutter app covers authentication, persistent secure session, lunch, basic
  fitness/nutrition, health, notifications, administration, and profile/logout.
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

## Verification completed this session

- Backend: `38` tests passed with Maven, including Flyway/PostgreSQL and the new
  empty-menu/new-user lunch regression test.
- Mobile: `flutter analyze` returned no issues.
- Mobile: all Flutter widget tests passed.
- Android release APK built successfully:
  `mobile/fittrack_mobile/build/app/outputs/flutter-apk/app-release.apk`.
- APK metadata: version `1.1.2`, version code `4`, size about `53.49 MB`.
- APK SHA-256:
  `B169470E67159011B494B741E10E0E90223A67280CECCD230E249659E6C88ADE`.
- APK manifest contains `android.permission.POST_NOTIFICATIONS`.
- Web checks were not rerun because this change set did not modify web source.

## Important decisions

- On phones, keep at most five bottom destinations; use **Thêm** for secondary
  destinations. Wide screens may continue using a full navigation rail.
- Ask for notification permission only after an in-app explanation. If permission
  is denied, send the user to OS app-notification settings.
- File import uses the operating system document picker and grants access only to
  the selected file. Do not request whole-device storage permission.
- A production `500` must be diagnosed using its request ID and Render stack trace.
  The screenshot reported as a lunch error actually highlighted **Luyện tập**;
  `/lunch/today` passes clean-database integration coverage.
- Production mail remains Brevo REST API because Render Free blocks conventional
  outbound SMTP ports.
- A sleeping Render Free instance must be called by an external uptime/cron
  service; an internal scheduler cannot wake its own stopped process.

## Known issues and risks

- The new Android APK still needs hands-on testing on the user's physical device
  with an admin account that has all module permissions.
- If lunch or fitness still returns `500` in production, capture the displayed
  request ID and search the same ID in Render logs. Do not treat the generic UI
  message as a confirmed lunch-service defect.
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

## Current task

Install and validate mobile release `1.1.2+4` on a real Android device, then
record the device-test result and any production request IDs in this document.

## Exact next steps

1. Install `mobile/fittrack_mobile/build/app/outputs/flutter-apk/app-release.apk`.
2. Log in with a full-permission admin and confirm the bottom bar has no more than
   five items and **Thêm** opens Notifications, Admin, Profile, and app permissions.
3. Accept the notification explanation and Android system permission; verify its
   state in **Thêm > Quyền ứng dụng**.
4. In Admin menu import, select a `.txt` or `.csv` file through the system picker,
   then import and send the menu notification.
5. Test lunch and fitness separately. If either fails, record `X-Request-Id` from
   the app error and correlate it with Render logs.
6. If device testing passes, record the accepted version here. If a production
   API fails, fix it in a separate focused commit with regression coverage.
7. Update and push this document after the test result or any new diagnosis.
