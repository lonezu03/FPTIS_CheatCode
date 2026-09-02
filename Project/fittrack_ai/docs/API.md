# FitTrack API Documentation

Base URL:

```txt
http://localhost:8080/api
```

Authentication:

```txt
Authorization: Bearer <JWT>
```

## Auth

### Register

```http
POST /auth/register
```

Request:

```json
{
  "email": "test@gmail.com",
  "password": "123456",
  "fullName": "Phan Thanh Vu",
  "height": 160,
  "weight": 60,
  "goal": "LEAN_BULK"
}
```

### Login

```http
POST /auth/login
```

Request:

```json
{
  "email": "test@gmail.com",
  "password": "123456"
}
```

Response:

```json
{
  "token": "...",
  "tokenType": "Bearer",
  "userId": "...",
  "email": "test@gmail.com",
  "fullName": "Phan Thanh Vu"
}
```

### Quên mật khẩu bằng OTP email

Yêu cầu OTP. API luôn trả thông báo chung để không làm lộ email nào đã đăng ký:

```http
POST /auth/forgot-password
```

```json
{
  "email": "test@gmail.com"
}
```

Đặt lại mật khẩu bằng mã OTP 6 chữ số nhận tại đúng email đã đăng ký. OTP có
hiệu lực 10 phút, chỉ dùng một lần và bị khóa sau 5 lần nhập sai:

```http
POST /auth/reset-password
```

```json
{
  "email": "test@gmail.com",
  "otp": "123456",
  "newPassword": "NewPassword123!"
}
```

Sau khi đổi mật khẩu, toàn bộ access/refresh token cũ của tài khoản bị thu hồi.

### Kiểm tra dịch vụ email (Admin)

```http
GET  /admin/notifications/mail-status
POST /admin/notifications/test-email
```

Email thử chỉ được gửi đến email đăng ký của chính admin đang đăng nhập; API
không nhận địa chỉ người nhận từ request.

### Yêu cầu mở module Rèn luyện

Tài khoản đã đăng nhập nhưng chưa có quyền Fitness có thể gửi yêu cầu đến các
admin đang hoạt động:

```http
POST /notifications/access-requests/fitness
```

Backend lấy tên, email và ID từ tài khoản đang xác thực; client không được truyền
thay danh tính người yêu cầu. Mỗi admin chỉ nhận tối đa một thông báo cho cùng
người dùng trong một ngày. Thông báo tham chiếu đến tài khoản người gửi để admin
mở màn Quản lý tài khoản và cấp quyền.

### Thông báo menu trưa (Admin)

Sau khi import menu, admin gọi API dưới đây (hoặc bấm **Thông báo menu** trên
màn hình điều phối cơm) để tạo thông báo trong ứng dụng và gửi email đến toàn bộ
tài khoản đang active và bật nhận email (`emailNotificationsEnabled=true`):

```http
POST /lunch/admin/menus/{menuId}/notify
```

Kết quả trả về gồm `emailEligibleCount`, `emailSentCount`, `emailFailedCount` và `emailSkippedCount`. `emailSkippedCount` là các tài khoản đã tắt nhận email, không phải lỗi gửi; chỉ `emailFailedCount` mới biểu thị provider email trả về thất bại. Thông báo trong ứng dụng vẫn được tạo cho các tài khoản active.

### Đặt nhiều phần cơm trong một lần

Mỗi phần `COMBO` chọn đúng hai lượt món thường, cho phép chọn trùng cùng một món; mỗi phần `SINGLE` chọn một món đặc biệt. `extraItemIds` là danh sách món thêm/đồ uống, có thể lặp để biểu diễn số lượng và được cộng theo `unitPrice`.
Toàn bộ request được xử lý trong một transaction: nếu một phần không hợp lệ hoặc phần trả hộ không đủ quỹ, không phần nào được tạo.
`clientRequestId` phải do client tạo, giữ nguyên khi người dùng gửi lại cùng giỏ vì mất kết nối; backend trả lại batch cũ thay vì ghi thêm nợ.

```http
POST /lunch/orders/batch
```

```json
{
  "menuId": "menu-id",
  "clientRequestId": "f6c0e174-1a3a-4a67-a52d-9b9408c75de8",
  "portions": [
    {
      "selectionType": "COMBO",
      "itemIds": ["regular-item-1", "regular-item-2"],
      "extraItemIds": ["drink-peach-tea", "drink-peach-tea"],
      "note": "Cơm thêm"
    },
    {
      "beneficiaryUserId": "optional-colleague-id",
      "selectionType": "SINGLE",
      "itemIds": ["special-item-1"],
      "note": ""
    }
  ]
}
```

### Sửa hoặc xóa menu nháp (Admin)

```http
PUT    /lunch/admin/menus/{menuId}
DELETE /lunch/admin/menus/{menuId}
```

`GET /lunch/today` trả `menus` và `requiresMenuSelection` khi có nhiều menu cùng ngày; `menu` vẫn được trả cho trường hợp chỉ có một menu để giữ tương thích client cũ. Mỗi `MenuResponse` có `coordinator`, `regularItems`, `specialItems` và `extraItems`.

`PUT` dùng cùng payload với import menu. Trong nội dung import, thêm `@DRINKS` hoặc `@EXTRAS`, sau đó nhập `Tên món | 45000` hoặc `Tên món 50000` để lưu giá riêng. Nhiều admin có thể import menu cùng ngày; user phải chọn menu/coordinator khi có từ hai menu trở lên.

Hai thao tác chỉ được chấp nhận khi menu
chưa có bất kỳ đơn nào và chưa được tổng hợp; nếu không API trả `409 Conflict` để
bảo toàn lịch sử đơn, công nợ và dữ liệu dinh dưỡng. Khi thay thế một menu nháp đã
đóng thủ công, menu được mở lại để nhận đơn theo giờ chốt mới.

## User Profile

```http
GET /users/me
PUT /users/me
```

Update request:

```json
{
  "fullName": "Phan Thanh Vu",
  "gender": "MALE",
  "age": 23,
  "height": 160,
  "weight": 60,
  "goal": "LEAN_BULK",
  "activityLevel": "MODERATE",
  "emailNotificationsEnabled": true
}
```

## Exercises

```http
GET /exercises
GET /exercises?keyword=squat
GET /exercises?includeInactive=true
POST /exercises
PUT /exercises/{id}
DELETE /exercises/{id}
PATCH /exercises/{id}/restore
```

Create request:

```json
{
  "name": "Bulgarian Split Squat",
  "muscleGroup": "Legs",
  "equipment": "Dumbbell",
  "description": "Single-leg squat variation."
}
```

## Workouts

```http
GET /workouts/sessions
GET /workouts/sessions/page?page=0&size=20
GET /workouts/previous-performance?exerciseId={exerciseId}
POST /workouts/sessions
PUT /workouts/sessions/{id}
DELETE /workouts/sessions/{id}
```

Create request:

```json
{
  "sessionDate": "2026-05-28",
  "note": "Push day",
  "durationMinutes": 60,
  "sets": [
    {
      "exerciseId": "...",
      "exerciseOrder": 1,
      "setNumber": 1,
      "setType": "WARMUP",
      "weight": 9,
      "reps": 10,
      "rir": 2,
      "restSeconds": 120,
      "completed": true
    },
    {
      "exerciseId": "...",
      "exerciseOrder": 1,
      "setNumber": 2,
      "setType": "NORMAL",
      "weight": 20,
      "reps": 10,
      "rir": 2,
      "restSeconds": 120,
      "completed": true
    }
  ]
}
```

`exerciseOrder` groups and orders exercises inside one session. `setNumber` is
the order within that exercise. `setType` accepts `WARMUP`, `NORMAL`, `DROP`, or
`FAILURE`. Web and mobile keep an in-progress workout locally, start the rest
timer after a set is checked, and submit only completed sets when the user
finishes the session. The previous-performance endpoint returns the most recent
session containing the requested exercise, scoped to the authenticated user.

## Workout Plans

```http
GET /workout-plans
POST /workout-plans
DELETE /workout-plans/{id}
POST /workout-plans/{id}/generate-session
```

Create request:

```json
{
  "name": "Push Pull Legs",
  "description": "3-day training plan",
  "days": [
    {
      "name": "Push Day",
      "dayOrder": 1,
      "exercises": [
        {
          "exerciseId": "...",
          "exerciseOrder": 1,
          "targetSets": 3,
          "targetReps": 10,
          "targetWeight": 9,
          "targetRir": 2
        }
      ]
    }
  ]
}
```

Generate session request:

```json
{
  "dayId": "...",
  "sessionDate": "2026-05-28",
  "note": "Generated Push Day"
}
```

## Foods

```http
GET /foods
GET /foods?keyword=chicken
GET /foods?includeInactive=true
POST /foods
PUT /foods/{id}
DELETE /foods/{id}
PATCH /foods/{id}/restore
```

Create request:

```json
{
  "name": "Greek Yogurt",
  "calories": 59,
  "protein": 10,
  "carbs": 3.6,
  "fat": 0.4,
  "unit": "100g",
  "servingSizeGrams": 100,
  "dataSourceType": "PRODUCT_LABEL",
  "dataSourceName": "Nhãn sản phẩm",
  "verified": false
}
```

`dataSourceType` nhận `VERIFIED_DATABASE`, `PRODUCT_LABEL`,
`RECIPE_CALCULATED`, `COMMUNITY`, hoặc `ESTIMATED`. Vi chất chưa biết nên để
`null`; không dùng `0` để biểu diễn thiếu dữ liệu. Chỉ admin được quyết định cờ
`verified`; món do user đề xuất luôn bắt đầu ở trạng thái chưa xác minh.

## Nutrition

```http
GET /nutrition/diary?date=2026-05-28
GET /nutrition/meal-logs?date=2026-05-28
POST /nutrition/meal-logs
PUT /nutrition/meal-logs/{id}
DELETE /nutrition/meal-logs/{id}
PUT /nutrition/days/2026-05-28/status
GET /nutrition/water-logs?date=2026-05-28
POST /nutrition/water-logs
DELETE /nutrition/water-logs/{id}
```

Nhật ký ngày trả về trạng thái chất lượng dữ liệu, tổng đã dùng, mục tiêu, phần
còn lại, lượng nước và các bữa đã nhóm. Trạng thái hợp lệ là `UNLOGGED`,
`PARTIAL`, `COMPLETE`, `FASTING`; ngày có món mặc định là `PARTIAL`, và chỉ
`COMPLETE`/`FASTING` được dùng trong báo cáo sức khỏe, thành tích và khuyến nghị.

Create/update meal request (field `quantity` cũ vẫn tương thích):

```json
{
  "mealType": "LUNCH",
  "logDate": "2026-05-28",
  "items": [
    {
      "foodId": "...",
      "servingAmount": 1.5,
      "servingUnit": "SERVING"
    },
    {
      "foodId": "...",
      "servingAmount": 180,
      "servingUnit": "GRAM"
    }
  ]
}
```

`servingUnit` nhận `SERVING`, `GRAM`, hoặc `ML`. `GRAM`/`ML` chỉ chuyển đổi
chính xác khi thực phẩm có `servingSizeGrams`.

```json
PUT /nutrition/days/2026-05-28/status
{ "status": "COMPLETE" }

POST /nutrition/water-logs
{ "amountMl": 350, "loggedAt": "2026-05-28T09:30:00" }
```

## Body Measurements

```http
GET /body-measurements
POST /body-measurements
PUT /body-measurements/{id}
DELETE /body-measurements/{id}
```

Create request:

```json
{
  "weight": 60,
  "waist": 78,
  "chest": 90,
  "arm": 30,
  "thigh": 52,
  "recordDate": "2026-05-28"
}
```

## Dashboard

```http
GET /dashboard/today
GET /dashboard/progress
```

## Weekly Report

```http
GET /reports/weekly
GET /reports/weekly?fromDate=2026-05-22&toDate=2026-05-28
```

## Recommendations

```http
GET /recommendations/weekly
GET /recommendations/weekly?fromDate=2026-05-22&toDate=2026-05-28
```

## Achievements

```http
GET /achievements/summary
```

## Demo Seed

```http
POST /demo/seed
```


## Todo / Personal Task Planner

Todo hỗ trợ task detail, thời gian bắt đầu, deadline, thời lượng dự kiến, priority, category, reminder và recurring. Endpoint cũ vẫn hoạt động khi chỉ gửi `title`, `priority`, `status` và `dueAt`; các field mới là tùy chọn.

```http
GET    /todos
POST   /todos
PATCH  /todos/{id}
POST   /todos/{id}/complete
POST   /todos/{id}/skip
DELETE /todos/{id}
```

`GET /todos` nhận các query tùy chọn `view=TODAY|OVERDUE|UPCOMING|ALL`, `category=WORK|STUDY|PERSONAL|HEALTH|FINANCE|SHOPPING` và `status=OPEN|IN_PROGRESS|DONE|SKIPPED|CANCELLED|ARCHIVED`. Nếu không truyền query, API trả toàn bộ task của user hiện tại.

```json
{
  "title": "Học tiếng Nhật 30 phút",
  "description": "Ôn bài 12 và viết lại 10 câu ví dụ.",
  "status": "OPEN",
  "priority": "HIGH",
  "category": "STUDY",
  "startAt": "2026-08-30T20:30:00",
  "dueAt": "2026-08-30T21:30:00",
  "estimatedMinutes": 45,
  "reminderAt": "2026-08-30T20:00:00",
  "reminderEnabled": true,
  "recurrenceRule": "WEEKLY",
  "recurrenceInterval": 1,
  "daysOfWeek": "MONDAY,WEDNESDAY,FRIDAY",
  "recurrenceBasis": "SCHEDULED_DATE",
  "recurrenceEndAt": null,
  "recurrenceMaxOccurrences": 30,
  "subtasks": [
    { "title": "Ôn bài 12", "completed": false, "sortOrder": 0 },
    { "title": "Viết 10 câu ví dụ", "completed": false, "sortOrder": 1 }
  ]
}
```

`recurrenceRule` có các giá trị `NONE`, `DAILY`, `WEEKLY`, `MONTHLY`, `YEARLY` và `CUSTOM`. Với `CUSTOM`, `recurrenceInterval` tính theo ngày; với `WEEKLY`, có thể thêm `daysOfWeek`. `recurrenceBasis=SCHEDULED_DATE` giữ lịch cố định; `COMPLETION_DATE` tính lần kế tiếp từ ngày user thực sự hoàn thành. `recurrenceEndAt` và `recurrenceMaxOccurrences` là hai giới hạn tùy chọn.

Khi task recurring được `complete` hoặc `skip`, backend giữ occurrence cũ, tạo đúng một occurrence kế tiếp trong cùng `recurringSeriesId`, reset checklist và tăng `occurrenceNumber`. Unique index theo series/occurrence ngăn việc nhấn lặp hoặc retry request sinh bản ghi trùng.

Todo reminder chạy theo phút trong múi giờ `Asia/Ho_Chi_Minh`, dùng notification infrastructure chung và deduplication key theo task cùng thời điểm reminder. User vẫn có thể tắt email notification ở hồ sơ; reminder trong app không bị biến thành email bắt buộc.

## Thời khóa biểu / Calendar

```http
GET    /schedule
GET    /schedule/calendar?from=2026-08-31T00:00:00&to=2026-09-07T00:00:00
POST   /schedule
PATCH  /schedule/{id}
DELETE /schedule/{id}
```

`/schedule` quản lý event/cuộc hẹn. Event hỗ trợ `repeatRule=NONE|DAILY|WEEKLY|MONTHLY|YEARLY`, `repeatInterval`, `daysOfWeek`, `repeatEndAt`, `endAt` và reminder. `/schedule/calendar` là read model hợp nhất: trả cả event (`sourceType=EVENT`) và Todo có `startAt`/`dueAt` (`sourceType=TODO`) trong khoảng tối đa 370 ngày. Client không tạo thêm bản ghi Schedule khi một Todo được time-block.
