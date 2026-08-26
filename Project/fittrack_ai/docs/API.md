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

### Thông báo menu trưa (Admin)

Sau khi import menu, admin gọi API dưới đây (hoặc bấm **Thông báo menu** trên
màn hình điều phối cơm) để tạo thông báo trong ứng dụng và gửi email đến toàn bộ
tài khoản đang active:

```http
POST /lunch/admin/menus/{menuId}/notify
```

### Đặt nhiều phần cơm trong một lần

Mỗi phần `COMBO` chọn đúng hai món thường; mỗi phần `SINGLE` chọn một món đặc biệt.
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

`PUT` dùng cùng payload với import menu. Hai thao tác chỉ được chấp nhận khi menu
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
  "activityLevel": "MODERATE"
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
      "setNumber": 1,
      "weight": 9,
      "reps": 10,
      "rir": 2
    }
  ]
}
```

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
  "unit": "100g"
}
```

## Nutrition

```http
GET /nutrition/meal-logs?date=2026-05-28
POST /nutrition/meal-logs
PUT /nutrition/meal-logs/{id}
DELETE /nutrition/meal-logs/{id}
```

Create request:

```json
{
  "mealType": "LUNCH",
  "logDate": "2026-05-28",
  "items": [
    {
      "foodId": "...",
      "quantity": 2
    },
    {
      "foodId": "...",
      "quantity": 3
    }
  ]
}
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
