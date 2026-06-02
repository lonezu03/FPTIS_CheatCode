# Backend Documentation

## Tech Stack

```txt
Java 21
Spring Boot
Spring Security
JWT
Spring Data JPA
Hibernate
H2
PostgreSQL-ready
Swagger
Docker
Maven
```

## Modules

```txt
auth
user
workout
workoutplan
nutrition
bodytracking
dashboard
report
recommendation
achievement
demo
common
```

## Common Package

The `common` package contains shared infrastructure:

- security
- exception
- config
- response

## Security

Security is handled by:

- `SecurityConfig`
- `JwtService`
- `JwtAuthFilter`

Public endpoints:

```txt
/api/auth/register
/api/auth/login
/api/health
/swagger-ui/**
/v3/api-docs/**
```

All other endpoints require JWT.

## Exception Handling

Global exceptions are handled by `GlobalExceptionHandler`.

Error response format:

```json
{
  "status": 400,
  "error": "Bad Request",
  "message": "Food not found",
  "timestamp": "..."
}
```

## DTO Strategy

The API does not return JPA entities directly.

Instead, it uses:

- Request DTO
- Response DTO
- Mapper

Benefits:

- Avoid JSON recursion
- Avoid leaking sensitive fields
- Stable API response
- Frontend-friendly data

## Soft Delete

Soft delete is used for:

- Exercise
- Food

Instead of deleting:

```txt
active = false
```

Archived items are hidden from dropdowns but preserved for historical data.

## Goal Engine

Goal engine calculates:

- BMR
- TDEE
- Target Calories
- Target Protein
- Target Carbs
- Target Fat

Based on:

- gender
- age
- height
- weight
- goal
- activityLevel

## Recommendation Engine

The recommendation engine analyzes weekly report data and generates action items.

Input:

- `WeeklyReportResponse`

Output:

- `WeeklyRecommendationResponse`

## Achievement Engine

Achievements are calculated dynamically from:

- Meal logs
- Workout sessions
- Body measurements
- Protein target
