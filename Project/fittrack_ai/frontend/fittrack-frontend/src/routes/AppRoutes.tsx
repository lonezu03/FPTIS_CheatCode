import { lazy, Suspense } from "react";
import { BrowserRouter, Navigate, Route, Routes } from "react-router-dom";
import ProtectedRoute from "./ProtectedRoute";
import AdminRoute from "./AdminRoute";
import AppLayout from "../components/AppLayout";
import PageLoading from "../components/common/PageLoading";
import FeatureRoute from "./FeatureRoute";

const LoginPage = lazy(() => import("../pages/LoginPage"));
const AuthRecoveryPage = lazy(() => import("../pages/AuthRecoveryPage"));
const DashboardPage = lazy(() => import("../pages/DashboardPage"));
const WorkoutPage = lazy(() => import("../pages/WorkoutPage"));
const WorkoutPlansPage = lazy(() => import("../pages/WorkoutPlansPage"));
const ExercisesPage = lazy(() => import("../pages/ExercisesPage"));
const FoodsPage = lazy(() => import("../pages/FoodsPage"));
const NutritionPage = lazy(() => import("../pages/NutritionPage"));
const BodyTrackingPage = lazy(() => import("../pages/BodyTrackingPage"));
const WeeklyReportPage = lazy(() => import("../pages/WeeklyReportPage"));
const AchievementsPage = lazy(() => import("../pages/AchievementsPage"));
const ProfilePage = lazy(() => import("../pages/ProfilePage"));
const HealthPage = lazy(() => import("../pages/HealthPage"));
const LunchPage = lazy(() => import("../pages/LunchPage"));
const AdminLunchPage = lazy(() => import("../pages/AdminLunchPage"));
const AdminUsersPage = lazy(() => import("../pages/AdminUsersPage"));
const AdminNotificationsPage = lazy(() => import("../pages/AdminNotificationsPage"));

export default function AppRoutes() {
  return (
    <BrowserRouter>
      <Suspense fallback={<RouteLoading />}>
        <Routes>
          <Route path="/login" element={<LoginPage />} />
          <Route path="/verify-email" element={<AuthRecoveryPage />} />
          <Route path="/forgot-password" element={<AuthRecoveryPage />} />
          <Route path="/reset-password" element={<AuthRecoveryPage />} />

          <Route element={<ProtectedRoute />}>
            <Route element={<AppLayout />}>
              <Route index element={<Navigate to="/dashboard" replace />} />
              <Route path="/dashboard" element={<DashboardPage />} />
              <Route element={<FeatureRoute feature="lunchEnabled" />}>
                <Route path="/lunch" element={<LunchPage />} />
              </Route>
              <Route element={<FeatureRoute feature="fitnessEnabled" />}>
                <Route path="/workouts" element={<WorkoutPage />} />
                <Route path="/workout-plans" element={<WorkoutPlansPage />} />
                <Route path="/exercises" element={<ExercisesPage />} />
                <Route path="/achievements" element={<AchievementsPage />} />
              </Route>
              <Route element={<FeatureRoute feature="healthEnabled" />}>
                <Route path="/foods" element={<FoodsPage />} />
                <Route path="/nutrition" element={<NutritionPage />} />
                <Route path="/body" element={<BodyTrackingPage />} />
                <Route path="/reports/weekly" element={<WeeklyReportPage />} />
                <Route path="/health" element={<HealthPage />} />
              </Route>
              <Route path="/profile" element={<ProfilePage />} />

              <Route element={<AdminRoute />}>
                <Route path="/admin/lunch" element={<AdminLunchPage />} />
                <Route path="/admin/users" element={<AdminUsersPage />} />
                <Route path="/admin/notifications" element={<AdminNotificationsPage />} />
              </Route>
            </Route>
          </Route>

          <Route path="*" element={<Navigate to="/dashboard" replace />} />
        </Routes>
      </Suspense>
    </BrowserRouter>
  );
}

function RouteLoading() {
  return (
    <div className="mx-auto w-full max-w-[1600px] p-5 sm:p-8">
      <PageLoading />
    </div>
  );
}
