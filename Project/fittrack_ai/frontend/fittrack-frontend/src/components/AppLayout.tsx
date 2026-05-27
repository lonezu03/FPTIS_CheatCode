import { NavLink, Outlet, useNavigate } from "react-router-dom";
import { useAuthStore } from "../store/auth.store";
import { Button } from "@/components/ui/button";

const navItems = [
  { to: "/dashboard", label: "Dashboard" },
  { to: "/workouts", label: "Workout" },
  { to: "/nutrition", label: "Nutrition" },
  { to: "/body", label: "Body" },
  { to: "/profile", label: "Profile" },
];

export default function AppLayout() {
  const logout = useAuthStore((state) => state.logout);
  const navigate = useNavigate();

  return (
    <div className="flex min-h-screen bg-slate-100">
      <aside className="hidden w-64 border-r bg-white p-6 md:block">
        <h1 className="mb-8 text-2xl font-bold">FitTrack</h1>

        <nav className="space-y-2">
          {navItems.map((item) => (
            <NavLink
              key={item.to}
              to={item.to}
              className={({ isActive }) =>
                `block rounded-xl px-4 py-3 text-sm font-medium ${
                  isActive ? "bg-slate-900 text-white" : "text-slate-600 hover:bg-slate-100"
                }`
              }
            >
              {item.label}
            </NavLink>
          ))}
        </nav>

        <Button
          variant="destructive"
          className="mt-8 w-full"
          onClick={() => {
            logout();
            navigate("/login");
          }}
        >
          Logout
        </Button>
      </aside>

      <main className="flex-1 p-6 md:p-8">
        <Outlet />
      </main>
    </div>
  );
}
