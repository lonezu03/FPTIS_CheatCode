import { Navigate, Outlet, useLocation } from "react-router-dom";
import { useAuthStore } from "../store/auth.store";

export default function AdminRoute() {
  const user = useAuthStore((state) => state.user);
  const location = useLocation();

  if (user?.role !== "ADMIN") {
    return <Navigate to="/lunch" replace state={{ from: location, reason: "admin-only" }} />;
  }

  return <Outlet />;
}
