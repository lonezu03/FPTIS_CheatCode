import { BrowserRouter, Navigate, Route, Routes } from "react-router-dom";
import ProtectedRoute from "./ProtectedRoute";
import AppLayout from "../components/AppLayout";

import LoginPage from "../pages/LoginPage";
import DashboardPage from "../pages/DashboardPage";
import WorkoutPage from "../pages/WorkoutPage";
import NutritionPage from "../pages/NutritionPage";
import BodyTrackingPage from "../pages/BodyTrackingPage";
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
            <Route path="/nutrition" element={<NutritionPage />} />
            <Route path="/body" element={<BodyTrackingPage />} />
            <Route path="/profile" element={<ProfilePage />} />
          </Route>
        </Route>

        <Route path="*" element={<Navigate to="/dashboard" replace />} />
      </Routes>
    </BrowserRouter>
  );
}
