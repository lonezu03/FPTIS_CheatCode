import { BrowserRouter, Navigate, Route, Routes } from "react-router-dom";
import ProtectedRoute from "./ProtectedRoute";
import AppLayout from "../components/AppLayout";

import LoginPage from "../pages/LoginPage";
import DashboardPage from "../pages/DashboardPage";
import WorkoutPage from "../pages/WorkoutPage";
import WorkoutPlansPage from "../pages/WorkoutPlansPage";
import ExercisesPage from "../pages/ExercisesPage";
import FoodsPage from "../pages/FoodsPage";
import NutritionPage from "../pages/NutritionPage";
import BodyTrackingPage from "../pages/BodyTrackingPage";
import WeeklyReportPage from "../pages/WeeklyReportPage";
import AchievementsPage from "../pages/AchievementsPage";
import ProfilePage from "../pages/ProfilePage";

export default function AppRoutes() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/login" element={<LoginPage />} />

        <Route element={<ProtectedRoute />}>
          <Route element={<AppLayout />}>
            <Route path="/dashboard" element={<DashboardPage />} />
            <Route path="/workouts" element={<WorkoutPage />} />
            <Route path="/workout-plans" element={<WorkoutPlansPage />} />
            <Route path="/exercises" element={<ExercisesPage />} />
            <Route path="/foods" element={<FoodsPage />} />
            <Route path="/nutrition" element={<NutritionPage />} />
            <Route path="/body" element={<BodyTrackingPage />} />
            <Route path="/reports/weekly" element={<WeeklyReportPage />} />
            <Route path="/achievements" element={<AchievementsPage />} />
            <Route path="/profile" element={<ProfilePage />} />
          </Route>
        </Route>

        <Route path="*" element={<Navigate to="/dashboard" replace />} />
      </Routes>
    </BrowserRouter>
  );
}
