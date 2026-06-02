import { useState } from "react";
import type { ElementType } from "react";
import { NavLink, Outlet, useLocation, useNavigate } from "react-router-dom";
import { useAuthStore } from "../store/auth.store";

import { Button } from "@/components/ui/button";
import { Sheet, SheetContent, SheetHeader, SheetTitle, SheetTrigger } from "@/components/ui/sheet";

import {
  Activity,
  Apple,
  BarChart3,
  CalendarDays,
  Dumbbell,
  FileBarChart,
  ListPlus,
  LogOut,
  Menu,
  Trophy,
  User,
  Utensils,
} from "lucide-react";

const navItems = [
  {
    to: "/dashboard",
    label: "Dashboard",
    icon: BarChart3,
  },
  {
    to: "/workouts",
    label: "Workout",
    icon: Dumbbell,
  },
  {
    to: "/workout-plans",
    label: "Plans",
    icon: CalendarDays,
  },
  {
    to: "/exercises",
    label: "Exercises",
    icon: ListPlus,
  },
  {
    to: "/foods",
    label: "Foods",
    icon: Utensils,
  },
  {
    to: "/nutrition",
    label: "Nutrition",
    icon: Apple,
  },
  {
    to: "/body",
    label: "Body",
    icon: Activity,
  },
  {
    to: "/reports/weekly",
    label: "Reports",
    icon: FileBarChart,
  },
  {
    to: "/achievements",
    label: "Achievements",
    icon: Trophy,
  },
  {
    to: "/profile",
    label: "Profile",
    icon: User,
  },
];

type NavItem = {
  to: string;
  label: string;
  icon: ElementType;
};

export default function AppLayout() {
  const logout = useAuthStore((state) => state.logout);
  const navigate = useNavigate();
  const location = useLocation();
  const [mobileOpen, setMobileOpen] = useState(false);

  const currentPage = navItems.find((item) => item.to === location.pathname)?.label ?? "FitTrack";

  const handleLogout = () => {
    logout();
    navigate("/login");
  };

  return (
    <div className="min-h-screen bg-slate-100">
      <aside className="fixed left-0 top-0 hidden h-screen w-64 border-r bg-white p-6 md:block">
        <Brand />

        <nav className="mt-8 space-y-2">
          {navItems.map((item) => (
            <SidebarLink key={item.to} item={item} />
          ))}
        </nav>

        <Button
          variant="destructive"
          className="absolute bottom-6 left-6 right-6 w-[calc(100%-3rem)]"
          onClick={handleLogout}
        >
          <LogOut className="mr-2 h-4 w-4" />
          Logout
        </Button>
      </aside>

      <header className="sticky top-0 z-40 flex h-16 items-center justify-between border-b bg-white px-4 md:hidden">
        <div>
          <p className="text-sm text-muted-foreground">FitTrack</p>
          <h1 className="font-semibold">{currentPage}</h1>
        </div>

        <Sheet open={mobileOpen} onOpenChange={setMobileOpen}>
          <SheetTrigger asChild>
            <Button variant="outline" size="icon">
              <Menu className="h-5 w-5" />
            </Button>
          </SheetTrigger>

          <SheetContent side="left" className="w-72">
            <SheetHeader>
              <SheetTitle>
                <Brand />
              </SheetTitle>
            </SheetHeader>

            <nav className="mt-8 space-y-2">
              {navItems.map((item) => (
                <MobileSidebarLink key={item.to} item={item} onClick={() => setMobileOpen(false)} />
              ))}
            </nav>

            <Button
              variant="destructive"
              className="mt-8 w-full"
              onClick={() => {
                setMobileOpen(false);
                handleLogout();
              }}
            >
              <LogOut className="mr-2 h-4 w-4" />
              Logout
            </Button>
          </SheetContent>
        </Sheet>
      </header>

      <main className="p-4 md:ml-64 md:p-8">
        <Outlet />
      </main>
    </div>
  );
}

function Brand() {
  return (
    <div>
      <h1 className="text-2xl font-bold tracking-tight">FitTrack</h1>
      <p className="text-sm text-muted-foreground">Fitness OS</p>
    </div>
  );
}

function SidebarLink({ item }: { item: NavItem }) {
  const Icon = item.icon;

  return (
    <NavLink
      to={item.to}
      className={({ isActive }) =>
        `flex items-center rounded-xl px-4 py-3 text-sm font-medium transition ${
          isActive ? "bg-slate-900 text-white" : "text-slate-600 hover:bg-slate-100 hover:text-slate-900"
        }`
      }
    >
      <Icon className="mr-3 h-4 w-4" />
      {item.label}
    </NavLink>
  );
}

function MobileSidebarLink({ item, onClick }: { item: NavItem; onClick: () => void }) {
  const Icon = item.icon;

  return (
    <NavLink
      to={item.to}
      onClick={onClick}
      className={({ isActive }) =>
        `flex items-center rounded-xl px-4 py-3 text-sm font-medium transition ${
          isActive ? "bg-slate-900 text-white" : "text-slate-600 hover:bg-slate-100 hover:text-slate-900"
        }`
      }
    >
      <Icon className="mr-3 h-4 w-4" />
      {item.label}
    </NavLink>
  );
}
