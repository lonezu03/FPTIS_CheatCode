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
