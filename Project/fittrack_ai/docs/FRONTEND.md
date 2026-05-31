# Frontend Documentation

## Tech Stack

```txt
React
TypeScript
Vite
React Router DOM
React Query
Zustand
TailwindCSS
shadcn/ui
Recharts
Sonner
Lucide React
```

## Folder Structure

```txt
src/
├── api/
├── components/
├── pages/
├── routes/
├── store/
├── App.tsx
└── main.tsx
```

## API Layer

All HTTP calls are placed in `src/api/`.

Examples:

- `auth.api.ts`
- `workout.api.ts`
- `nutrition.api.ts`
- `report.api.ts`
- `recommendation.api.ts`
- `achievement.api.ts`

Benefits:

- Keeps pages clean
- Centralizes backend integration
- Easier to update endpoints
- Easier to type API responses

## Authentication

Token is stored in `localStorage` using Zustand.

The Axios client automatically attaches:

```txt
Authorization: Bearer <token>
```

## Routing

Protected routes are handled by `ProtectedRoute.tsx`.

Main routes:

```txt
/login
/dashboard
/workouts
/workout-plans
/exercises
/foods
/nutrition
/body
/reports/weekly
/achievements
/profile
```

## React Query

React Query is used for:

- Fetching data
- Caching data
- Mutations
- Invalidating stale data

Common query keys:

- `dashboard-today`
- `dashboard-progress`
- `workout-sessions`
- `workout-plans`
- `exercises`
- `foods`
- `meal-logs`
- `body-measurements`
- `weekly-report`
- `weekly-recommendations`
- `achievements`
- `profile`

## UI System

The UI uses:

- TailwindCSS
- shadcn/ui
- lucide-react

Common components:

- Card
- Button
- Input
- Table
- Dialog
- Sheet
- Badge
- Progress

## Charts

Charts are built using Recharts.

Used for:

- Weight trend
- Waist trend
- Calories trend
- Protein trend
- Weekly report charts

## Toast Notifications

Sonner is used for feedback:

- Create success
- Update success
- Delete success
- API errors
