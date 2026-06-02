# FitTrack Architecture

## 1. System Overview

FitTrack is a modular monolith fullstack application.

```txt
Frontend React App
        |
        v
REST API
        |
        v
Spring Boot Backend
        |
        v
Database
```

## 2. Backend Architecture

The backend is organized by feature modules.

```txt
com.fittrack
├── auth
├── user
├── workout
├── workoutplan
├── nutrition
├── bodytracking
├── dashboard
├── report
├── recommendation
├── achievement
├── demo
└── common
```

Each module follows this flow:

```txt
controller -> service -> repository -> database
                |
              mapper
                |
               dto
```

## 3. Why Modular Monolith?

A modular monolith was chosen because it is easier to build and operate than microservices while still keeping business domains separated. It is a strong fit for an MVP and portfolio project, and individual modules can be extracted later if needed.

## 4. Authentication Flow

```txt
User submits login
        |
        v
Backend validates email/password
        |
        v
Backend returns JWT
        |
        v
Frontend stores JWT in localStorage
        |
        v
Axios attaches JWT to Authorization header
        |
        v
Backend validates token per request
```

Authorization header:

```txt
Authorization: Bearer <token>
```

## 5. Frontend Architecture

```txt
src/
├── api
├── components
├── pages
├── routes
├── store
└── main.tsx
```

### API Layer

All backend requests are isolated in `src/api/`.

Examples:

- `auth.api.ts`
- `workout.api.ts`
- `nutrition.api.ts`
- `report.api.ts`
- `recommendation.api.ts`
- `achievement.api.ts`

### Pages

Each page represents a feature screen:

- DashboardPage
- WorkoutPage
- NutritionPage
- WorkoutPlansPage
- WeeklyReportPage
- AchievementsPage

### State Management

- Zustand for authentication token
- React Query for server state

## 6. Data Fetching Strategy

React Query is used for fetching, caching, mutations, and invalidating stale data.

Example invalidation after creating a meal log:

- `meal-logs`
- `dashboard-today`
- `dashboard-progress`
- `weekly-report`
- `weekly-recommendations`
- `achievements`

## 7. Soft Delete Strategy

Exercise and Food use soft delete.

```txt
active = false
```

Benefits:

- Prevents foreign key errors
- Preserves workout and nutrition history
- Archived items disappear from dropdowns
- Archived items can be restored later

## 8. Goal Calculation

User profile stores weight, height, age, gender, goal, and activity level.

The backend calculates:

- BMR
- TDEE
- Target Calories
- Target Protein
- Target Carbs
- Target Fat

These values are used by Dashboard, Nutrition, Weekly Report, Recommendation Engine, and Achievements.

## 9. Weekly Report Logic

Weekly report aggregates:

- Meal logs
- Workout sessions
- Body measurements
- User goals

It calculates:

- Average calories
- Average protein
- Workout days
- Body changes
- Target compliance
- Insights

## 10. Recommendation Engine

The recommendation engine reads weekly report output and generates action items.

Examples:

- Calories too low -> increase calories
- Protein too low -> add protein serving
- Workout days low -> train at least 3 days
- Weight and waist increase fast -> reduce calories slightly

## 11. Achievement System

Achievement system tracks:

- Meal logging streak
- Workout streak
- Protein target hit days
- Body tracking days
- Weekly workout goals

Achievements are calculated dynamically from logs.

## 12. Demo Seed Module

Demo seed module creates sample data for portfolio demos.

It generates:

- Foods
- Exercises
- Meal logs
- Workout sessions
- Body measurements

This allows the dashboard, reports, recommendations, and achievements to show meaningful data instantly.
