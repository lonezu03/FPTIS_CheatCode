import { Navigate, Outlet } from "react-router-dom";
import { useAuthStore } from "@/store/auth.store";
import type { FeaturePermission } from "@/lib/feature-access";

export default function FeatureRoute({ feature }: { feature: FeaturePermission }) {
  const user = useAuthStore((state) => state.user);

  if (user?.role === "ADMIN" || user?.[feature] !== false) {
    return <Outlet />;
  }
  return <Navigate to="/dashboard" replace />;
}
