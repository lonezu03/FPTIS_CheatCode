# FitTrack Current Project State

Last updated: 2026-09-15

## Repository and deployment

- Repository: `lonezu03/FPTIS_CheatCode`, branch `main`.
- FitTrack root: `Project/fittrack_ai/`.
- Current pushed baseline: `4827472b` (`15092026- Lần 2`).
- Active backend: `backend/`; do not use or stage `backend/demo/`.
- Web source: `frontend/fittrack-frontend/`; Vercel build root remains
  `frontend/`.
- Production web: `https://datcom-nhalam.vercel.app`.
- Production API:
  `https://https-github-com-lonezu03-fptis.onrender.com/api`.
- Production schema uses Flyway and `ddl-auto=validate`. Source migrations are
  currently committed through V25; production `flyway_schema_history` has not
  been checked during this session.

## Current task: Finance transaction-list production hotfix

Status: Finance V1 backend/web is pushed. A local hotfix now addresses the
production HTTP 500 on `GET /api/finance/transactions` when optional filters are
absent. It is verified and awaiting commit, push and Render deployment. The user
explicitly deferred all mobile Finance work, so `mobile/` remains unchanged.

### Current production hotfix

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

### Completed in the current local follow-up

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

- Full backend Maven suite passed after the transaction-query hotfix: 91 tests,
  0 failures/errors; the two
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

1. Commit/push the Finance transaction-query hotfix and this context update.
2. Deploy only the backend on Render; this hotfix has no web or schema change.
3. Retry the exact September transaction request and confirm HTTP 200.
4. As admin, grant Finance to one non-admin user. Verify a user without Finance
   gets HTTP 403 and sees no Finance navigation/guide/dashboard card.
5. With the permitted user: create two accounts and an income; add an expense
   with a transaction-level nature override; transfer between accounts and
   confirm it does not change monthly income/expense.
6. Create/edit/void a transaction, create a category with a parent, set an 80%
   budget, create/edit/confirm a recurring item and verify its next due date.
7. Preserve `X-Request-Id` and correlate Render logs for any production failure.

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
