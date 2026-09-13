# Changelog

Các thay đổi đáng chú ý của FitTrack được ghi tại đây. Dự án dùng release tag
theo dạng `fittrack-vYYYY.MM.DD.N`; chỉ tạo tag sau khi production smoke test đạt.

## [Unreleased]

### Added

- Workout Intelligence V19: progressive-overload suggestions, derived personal
  records/e1RM, weekly volume by muscle group, per-user exercise preferences and
  ranked equivalent-exercise replacement on web and Flutter.
- Flyway V19 adds owner-scoped exercise preferences and supporting indexes.
- Public liveness/readiness probes cho hạ tầng triển khai.
- Version và source commit trong `GET /api/health`.
- CI gate bắt buộc hai PostgreSQL/Testcontainers suite phải thực sự chạy.
- Tài liệu release checklist, security và system design.

### Changed

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
