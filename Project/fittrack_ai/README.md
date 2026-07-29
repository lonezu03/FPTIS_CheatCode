# FitTrack - Fullstack Fitness and Nutrition Platform

FitTrack is a fullstack fitness and nutrition tracking platform built with Spring Boot, React TypeScript, JWT authentication, React Query, TailwindCSS, shadcn/ui, and a PostgreSQL-ready data model.

The application helps users track workouts, nutrition, body measurements, weekly progress, achievements, and smart recommendations based on their personal goals.

## Features

### Authentication
- User registration and login
- JWT-based authentication
- Protected frontend routes
- Axios token interceptor
- Admin-only account management with role assignment, account lock/unlock, and password reset

### User Profile and Goal Engine
- Profile management
- Height, weight, age, gender, goal, and activity level
- BMR and TDEE calculation
- Target calories and macro targets

### Workout Tracking
- Create workout sessions
- Log exercise sets with weight, reps, and RIR
- Custom workout date
- Edit and delete workout sessions
- Workout history

### Workout Plans
- Create reusable workout plans
- Multiple training days per plan
- Multiple exercises per day
- Target sets, reps, weight, and RIR
- Generate workout sessions from a plan

### Exercise Library
- Create custom exercises
- Edit exercises
- Archive and restore exercises
- Search exercises
- Soft delete to preserve workout history

### Nutrition Tracking
- Log meals by date
- Add multiple food items per meal
- Track calories, protein, carbs, and fat
- Edit and delete meal logs
- Compare daily intake against personal targets

### Lunch Ordering and Team Fund
- Admin imports the vendor's daily menu from plain text using `+` as the regular/special dish separator
- Users choose either two regular dishes or one special dish, for themselves or a colleague
- Configurable cutoff, default 35,000 VND price, wallet debit, unpaid fallback, and external-payment confirmation
- Admin fund top-up, payment reconciliation, order summary, dish counts, and copy-ready vendor text
- Full Vietnamese workflow: [docs/LUNCH_ORDERING.md](docs/LUNCH_ORDERING.md)

### Food Library
- Create custom foods
- Edit foods
- Archive and restore foods
- Search foods
- Soft delete to preserve historical meal data

### Body Tracking
- Log body weight, waist, chest, arm, and thigh
- Custom measurement date
- Edit and delete measurements
- Progress charts

### Dashboard
- Daily calories and macros
- Daily macro goal progress
- Workout count and meal count
- Latest workout
- Progress charts
- Smart suggestions
- Achievement summary

### Weekly Report
- Weekly average calories, protein, carbs, and fat
- Workout frequency
- Body weight and waist changes
- Nutrition compliance
- Weekly insights

### Smart Recommendation Engine
- Calories suggestions
- Protein suggestions
- Workout frequency suggestions
- Body progress suggestions
- Weekly action items

### FitTrack PT Assistant
- Uses the OpenAI Responses API from the backend only
- Understands the current user profile, food catalog, exercise catalog, recent logs, and today's lunch menu
- Can propose workout sessions, meal logs, and lunch orders
- Requires explicit user confirmation before any proposed action is saved
- Keeps the OpenAI API key out of the browser and source control

### Achievements
- Meal logging streak
- Workout streak
- Protein target hit days
- Body tracking consistency
- Weekly workout milestones

### Demo Data
- One-click demo data seed
- Creates sample foods, exercises, meals, workouts, and body measurements
- Useful for portfolio demos

## Tech Stack

### Backend
- Java 21
- Spring Boot
- Spring Security
- JWT Authentication
- Spring Data JPA
- Hibernate
- H2 for local quick start
- PostgreSQL-ready configuration
- Swagger / OpenAPI
- Maven

### Frontend
- React
- TypeScript
- Vite
- React Router DOM
- React Query
- Zustand
- TailwindCSS
- shadcn/ui
- Recharts
- Sonner Toast
- Lucide React Icons

## Project Structure

```txt
fittrack_ai/
├── backend/
│   └── demo/
│       ├── src/main/java/com/fittrack/
│       │   ├── auth/
│       │   ├── user/
│       │   ├── workout/
│       │   ├── workoutplan/
│       │   ├── nutrition/
│       │   ├── bodytracking/
│       │   ├── dashboard/
│       │   ├── report/
│       │   ├── recommendation/
│       │   ├── achievement/
│       │   ├── demo/
│       │   └── common/
│       ├── src/main/resources/
│       ├── docker-compose.yml
│       └── pom.xml
│
├── frontend/
│   └── fittrack-frontend/
│       ├── src/
│       │   ├── api/
│       │   ├── components/
│       │   ├── pages/
│       │   ├── routes/
│       │   ├── store/
│       │   └── main.tsx
│       ├── package.json
│       └── vite.config.ts
│
└── docs/
```

## Backend Architecture

The backend follows a modular monolith structure. Each feature module owns its controller, service, repository, entity, DTO, and mapper classes.

```txt
controller -> service -> repository -> database
                |
              mapper
                |
               dto
```

| Module | Responsibility |
| --- | --- |
| Auth | Register, login, JWT |
| User | Profile and goal engine |
| Workout | Workout sessions and sets |
| Workout Plan | Reusable workout plans |
| Exercise | Exercise library |
| Nutrition | Meal logs and macros |
| Food | Food library |
| Body Tracking | Body measurement logs |
| Dashboard | Daily summary and progress |
| Report | Weekly report |
| Recommendation | Smart suggestions |
| Achievement | Streaks and gamification |
| Demo | Seed demo data |

## Database Overview

Main tables:

- `users`
- `exercises`
- `workout_sessions`
- `workout_sets`
- `workout_plans`
- `workout_plan_days`
- `workout_plan_exercises`
- `foods`
- `meal_logs`
- `meal_items`
- `body_measurements`

Important relationships:

- User 1 - N WorkoutSession
- WorkoutSession 1 - N WorkoutSet
- Exercise 1 - N WorkoutSet
- User 1 - N WorkoutPlan
- WorkoutPlan 1 - N WorkoutPlanDay
- WorkoutPlanDay 1 - N WorkoutPlanExercise
- Exercise 1 - N WorkoutPlanExercise
- User 1 - N MealLog
- MealLog 1 - N MealItem
- Food 1 - N MealItem
- User 1 - N BodyMeasurement

## API Overview

Base URL:

```txt
http://localhost:8081/api
```

Key endpoints:

```txt
POST   /auth/register
POST   /auth/login
GET    /users/me
PUT    /users/me
GET    /admin/users
PATCH  /admin/users/{id}
POST   /admin/users/{id}/reset-password
GET    /health
GET    /dashboard/today
GET    /dashboard/progress
GET    /workouts/sessions
POST   /workouts/sessions
PUT    /workouts/sessions/{id}
DELETE /workouts/sessions/{id}
GET    /exercises
POST   /exercises
PUT    /exercises/{id}
DELETE /exercises/{id}
PATCH  /exercises/{id}/restore
GET    /foods
POST   /foods
PUT    /foods/{id}
DELETE /foods/{id}
PATCH  /foods/{id}/restore
GET    /nutrition/meal-logs
POST   /nutrition/meal-logs
PUT    /nutrition/meal-logs/{id}
DELETE /nutrition/meal-logs/{id}
GET    /body-measurements
POST   /body-measurements
PUT    /body-measurements/{id}
DELETE /body-measurements/{id}
GET    /workout-plans
POST   /workout-plans
POST   /workout-plans/{id}/generate-session
GET    /reports/weekly
GET    /recommendations/weekly
GET    /achievements/summary
POST   /demo/seed
GET    /lunch/today
GET    /lunch/people
GET    /lunch/orders/history
GET    /lunch/wallet/transactions
POST   /lunch/orders
PUT    /lunch/orders/{id}
DELETE /lunch/orders/{id}
GET    /lunch/admin/menus
POST   /lunch/admin/menus/import
GET    /lunch/admin/menus/{id}/orders
POST   /lunch/admin/menus/{id}/close
POST   /lunch/admin/menus/{id}/reopen
POST   /lunch/admin/menus/{id}/summarize
GET    /lunch/admin/members
POST   /lunch/admin/funds/top-up
POST   /lunch/admin/orders/{id}/confirm-external
POST   /assistant/chat
POST   /assistant/actions/execute
```

Full API documentation is available in [docs/API.md](docs/API.md).

The lunch ordering workflow and reconciliation rules are documented in [docs/LUNCH_ORDERING.md](docs/LUNCH_ORDERING.md).

Deployment instructions are available in [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md).

## Setup Guide

### Prerequisites

- Java 21
- Node.js 20+
- Maven
- Docker
- PostgreSQL, optional for production-like local runs

### Backend Setup

```bash
cd backend
./mvnw spring-boot:run -Dspring-boot.run.profiles=local
```

The `local` profile uses an embedded H2 database stored under `backend/data/`, so PostgreSQL is not required for local development. On Windows, use `mvnw.cmd` instead of `./mvnw`.

Backend URL:

```txt
http://localhost:8081
```

Swagger URL:

```txt
http://localhost:8081/swagger-ui/index.html
```

### Docker Compose

```bash
docker compose up -d --build
```

Open the frontend at `http://localhost:3000`. The Docker frontend calls the
Docker backend at `http://localhost:8082/api`. Port `8082` avoids a conflict
with the local IntelliJ backend running on `8081`. To use another host port,
set `BACKEND_HOST_PORT` before starting Compose.

```powershell
$env:BACKEND_HOST_PORT = "8090"
docker compose up -d --build
```

Lunch admin access is controlled by the `ADMIN_EMAILS` environment variable. Use a comma-separated list and restart the backend after changing it:

```bash
export ADMIN_EMAILS="admin@company.com,backup-admin@company.com"
```

On PowerShell:

```powershell
$env:ADMIN_EMAILS = "admin@company.com,backup-admin@company.com"
```

Configure the AI assistant only on the backend. Never add the key to a
`VITE_` variable because Vite exposes those values to browsers:

```bash
export OPENAI_API_KEY="replace-with-a-new-key"
export OPENAI_MODEL="gpt-5.6-terra"
export OPENAI_REQUESTS_PER_MINUTE="6"
```

The public `GET /api/health` endpoint verifies both the application and its
database connection. On Render, the optional keep-alive scheduler calls this
endpoint every 10 minutes:

```bash
export KEEP_ALIVE_ENABLED="true"
export KEEP_ALIVE_INTERVAL_MS="600000"
```

Render provides `RENDER_EXTERNAL_URL` automatically. For other hosts, set
`KEEP_ALIVE_URL` to the public backend URL. Keep-alive is disabled by default
outside production.

### Frontend Setup

```bash
cd frontend/fittrack-frontend
npm install
npm run dev
```

Frontend URL:

```txt
http://localhost:5173
```

### Demo Account

You can register a new user from the frontend.

Example:

```txt
email: test@gmail.com
password: 123456
```

After login, call the demo seed endpoint to generate sample data:

```txt
POST /api/demo/seed
```

## Screenshots

Add screenshots here after UI is ready:

```txt
docs/screenshots/dashboard.png
docs/screenshots/nutrition.png
docs/screenshots/workout-plans.png
docs/screenshots/weekly-report.png
docs/screenshots/achievements.png
```

## Key Learning Points

This project demonstrates:

- Fullstack architecture
- JWT authentication
- Modular backend design
- DTO-based API responses
- Entity relationship modeling
- Soft delete strategy
- React Query data fetching
- Protected routes
- Responsive dashboard UI
- Business logic implementation
- Smart recommendations
- Weekly analytics
- Gamification

## Future Improvements

- Form validation with React Hook Form and Zod
- Role-based admin panel
- Image upload for body progress photos
- AI-generated workout plans
- Longer-lived AI conversation history
- Export weekly report as PDF
- Mobile app version
- Deployment with Docker Compose
- CI/CD pipeline

## Author

Built by Phan Thanh Vu as a fullstack portfolio project.
