# Changelog

Các thay đổi đáng chú ý của FitTrack được ghi tại đây. Dự án dùng release tag
theo dạng `fittrack-vYYYY.MM.DD.N`; chỉ tạo tag sau khi production smoke test đạt.

## [Unreleased]

### Added

- Personal Finance V1 for permissioned users: owner-scoped money accounts,
  positive-value income/expense/transfer transactions, five expense-nature
  groups, category budgets with 80%/100% alerts, user-confirmed recurring items,
  monthly reports and a responsive web dashboard.
- `financeEnabled` account permission and Flyway V25 Finance schema.
- Full web create/edit/archive workflows, transaction filters/pagination and a
  permission-aware Finance usage guide, recent-category shortcuts and recurring
  snooze action.
- Workout Intelligence V19: progressive-overload suggestions, derived personal
  records/e1RM, weekly volume by muscle group, per-user exercise preferences and
  ranked equivalent-exercise replacement on web and Flutter.
- Flyway V19 adds owner-scoped exercise preferences and supporting indexes.
- Public liveness/readiness probes cho hạ tầng triển khai.
- Version và source commit trong `GET /api/health`.
- CI gate bắt buộc hai PostgreSQL/Testcontainers suite phải thực sự chạy.
- Tài liệu release checklist, security và system design.

### Changed

- Finance forms now expose transaction-level expense classification, preserve
  archived history, stop recurring rules when their account is archived and
  reject invalid category-parent combinations.
- Workout-session creation now returns newly achieved PRs without changing the
  existing set payload; warm-up sets do not affect PR/progression/weekly volume.
- SMTP không còn làm health tổng hợp `DOWN` mặc định khi production dùng Brevo
  REST API.
- Tài liệu backend, frontend và architecture được đồng bộ với source hiện tại.

## Baseline 2026-09-12

- Source baseline: commit `0a02f7b2` trên branch `main`.
- Flyway source baseline: `V18__quote_module_permission.sql`.
- Trạng thái commit/migration đang chạy trên production phải được xác nhận theo
  [RELEASE_CHECKLIST.md](docs/RELEASE_CHECKLIST.md) trước khi tạo release tag.
