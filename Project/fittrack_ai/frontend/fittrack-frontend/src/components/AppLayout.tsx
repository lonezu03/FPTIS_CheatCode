import { useMemo, useState, type ElementType } from "react";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { Link, NavLink, Outlet, useLocation, useNavigate } from "react-router-dom";
import { getProfile } from "../api/user.api";
import { useAuthStore } from "../store/auth.store";
import { Button } from "@/components/ui/button";
import { Sheet, SheetContent, SheetHeader, SheetTitle, SheetTrigger } from "@/components/ui/sheet";
import {
  Activity,
  Apple,
  BellRing,
  CalendarDays,
  ChevronRight,
  Dumbbell,
  FileBarChart,
  HeartPulse,
  LayoutDashboard,
  ListPlus,
  LogOut,
  Menu,
  ChefHat,
  ShieldCheck,
  Soup,
 
  Trophy,
  User,
  UsersRound,
  Utensils,
} from "lucide-react";
 
import NotificationBell from "@/components/notifications/NotificationBell";
import AssistantChat from "@/components/assistant/AssistantChat";
import { canUseFeature, type FeaturePermission } from "@/lib/feature-access";
import { logoutApi } from "@/api/auth.api";

type NavItem = {
  to: string;
  label: string;
  description?: string;
  icon: ElementType;
  adminOnly?: boolean;
  highlight?: boolean;
  feature?: FeaturePermission;
};

type NavGroup = {
  label: string;
  items: NavItem[];
};

const navGroups: NavGroup[] = [
  {
    label: "Không gian của bạn",
    items: [
      { to: "/dashboard", label: "Tổng quan", description: "Hôm nay", icon: LayoutDashboard },
      { to: "/lunch", label: "Đặt cơm", description: "Menu hằng ngày", icon: Soup, highlight: true, feature: "lunchEnabled" },
      { to: "/todos", label: "Việc cần làm", description: "Task cá nhân", icon: ListPlus, feature: "todoEnabled" },
      { to: "/schedule", label: "Thời khóa biểu", description: "Lịch & nhắc việc", icon: CalendarDays, feature: "scheduleEnabled" },
    ],
  },
  {
    label: "Luyện tập",
    items: [
      { to: "/workouts", label: "Buổi tập", icon: Dumbbell, feature: "fitnessEnabled" },
      { to: "/workout-plans", label: "Giáo án", icon: CalendarDays, feature: "fitnessEnabled" },
      { to: "/exercises", label: "Kho bài tập", icon: ListPlus, feature: "fitnessEnabled" },
    ],
  },
  {
    label: "Dinh dưỡng & tiến độ",
    items: [
      { to: "/nutrition", label: "Nhật ký ăn uống", icon: Apple, feature: "healthEnabled" },
      { to: "/foods", label: "Kho thực phẩm", icon: Utensils, feature: "healthEnabled" },
      { to: "/body", label: "Chỉ số cơ thể", icon: Activity, feature: "healthEnabled" },
      { to: "/health", label: "Sức khỏe toàn diện", icon: HeartPulse, feature: "healthEnabled" },
      { to: "/reports/weekly", label: "Báo cáo tuần", icon: FileBarChart, feature: "healthEnabled" },
      { to: "/achievements", label: "Thành tích", icon: Trophy, feature: "fitnessEnabled" },
    ],
  },
  {
    label: "Hệ thống",
    items: [
      { to: "/profile", label: "Hồ sơ cá nhân", icon: User },
      { to: "/admin/lunch", label: "Điều phối cơm", icon: ShieldCheck, adminOnly: true },
      { to: "/admin/users", label: "Quản lý tài khoản", icon: UsersRound, adminOnly: true },
      { to: "/admin/notifications", label: "Gửi thông báo", icon: BellRing, adminOnly: true },
      { to: "/admin/notification-playbooks", label: "Kịch bản notification", icon: BellRing, adminOnly: true },
    ],
  },
];

export default function AppLayout() {
  const queryClient = useQueryClient();
  const logout = useAuthStore((state) => state.logout);
  const authUser = useAuthStore((state) => state.user);
  const navigate = useNavigate();
  const location = useLocation();
  const [mobileOpen, setMobileOpen] = useState(false);

  const profileQuery = useQuery({
    queryKey: ["profile"],
    queryFn: async () => {
      const profile = await getProfile();
      useAuthStore.getState().updateUser({
        userId: profile.id,
        email: profile.email,
        fullName: profile.fullName,
        role: profile.role,
        lunchEnabled: profile.lunchEnabled,
        fitnessEnabled: profile.fitnessEnabled,
        healthEnabled: profile.healthEnabled,
        chatbotEnabled: profile.chatbotEnabled,
        todoEnabled: profile.todoEnabled,
        scheduleEnabled: profile.scheduleEnabled,
        passwordChangeRequired: profile.passwordChangeRequired,
      });
      return profile;
    },
    staleTime: 5 * 60 * 1000,
  });

  const isAdmin = (profileQuery.data?.role ?? authUser?.role) === "ADMIN";
  const visibleGroups = useMemo(
    () =>
      navGroups
        .map((group) => ({
          ...group,
          items: group.items.filter(
            (item) =>
              (!item.adminOnly || isAdmin) &&
              (!item.feature || canUseFeature(authUser, item.feature)),
          ),
        }))
        .filter((group) => group.items.length > 0),
    [authUser, isAdmin],
  );
  const allItems = visibleGroups.flatMap((group) => group.items);
  const currentPage =
    [...allItems]
      .sort((a, b) => b.to.length - a.to.length)
      .find((item) => location.pathname === item.to || location.pathname.startsWith(`${item.to}/`))?.label ??
    "FitTrack";
  const displayName = profileQuery.data?.fullName || authUser?.fullName || "Thành viên FitTrack";
  const displayEmail = profileQuery.data?.email || authUser?.email || "";
  const initials = getInitials(displayName);
  const todayLabel = new Intl.DateTimeFormat("vi-VN", {
    weekday: "long",
    day: "2-digit",
    month: "2-digit",
    year: "numeric",
  }).format(new Date());

  const handleLogout = async () => {
    try {
      await logoutApi();
    } catch {
      // Clearing the local session remains safe when the server is unavailable.
    }
    logout();
    queryClient.clear();
    navigate("/login", { replace: true });
  };

  return (
    <div className="min-h-screen bg-background text-foreground">
      <aside className="fixed inset-y-0 left-0 z-50 hidden w-[17.5rem] border-r border-white/8 bg-[#0c2821] text-white lg:flex lg:flex-col">
        <div className="px-5 pb-4 pt-5">
          <Brand />
        </div>

        <nav className="min-h-0 flex-1 overflow-y-auto px-3 pb-4" aria-label="Điều hướng chính">
          {visibleGroups.map((group) => (
            <div key={group.label} className="mb-5">
              <p className="mb-1.5 px-3 text-[0.68rem] font-semibold uppercase tracking-[0.16em] text-emerald-50/35">
                {group.label}
              </p>
              <div className="space-y-1">
                {group.items.map((item) => (
                  <SidebarLink key={item.to} item={item} />
                ))}
              </div>
            </div>
          ))}
        </nav>

        <div className="border-t border-white/8 p-3">
          <div className="flex items-center gap-3 rounded-2xl bg-white/[0.06] p-2.5">
            <Avatar initials={initials} />
            <div className="min-w-0 flex-1">
              <p className="truncate text-sm font-semibold text-white">{displayName}</p>
              <p className="truncate text-[0.7rem] text-emerald-50/45">
                {isAdmin ? "Quản trị viên" : displayEmail}
              </p>
            </div>
            <button
              type="button"
              onClick={handleLogout}
              aria-label="Đăng xuất"
              className="grid size-9 shrink-0 place-items-center rounded-xl text-emerald-50/55 transition hover:bg-white/10 hover:text-white"
            >
              <LogOut className="size-4" />
            </button>
          </div>
        </div>
      </aside>

      <div className="lg:pl-[17.5rem]">
        <header className="sticky top-0 z-40 border-b border-border/70 bg-background/88 backdrop-blur-xl">
          <div className="mx-auto flex h-[4.25rem] max-w-[1600px] items-center justify-between gap-4 px-4 sm:px-6 lg:px-8">
            <div className="flex min-w-0 items-center gap-3">
              <Sheet open={mobileOpen} onOpenChange={setMobileOpen}>
                <SheetTrigger asChild>
                  <Button variant="outline" size="icon" className="lg:hidden" aria-label="Mở menu">
                    <Menu className="size-5" />
                  </Button>
                </SheetTrigger>
                <SheetContent side="left" className="w-[19rem] border-none bg-[#0c2821] p-0 text-white">
                  <SheetHeader className="border-b border-white/8 px-5 py-5 text-left">
                    <SheetTitle>
                      <Brand />
                    </SheetTitle>
                  </SheetHeader>
                  <nav className="min-h-0 flex-1 overflow-y-auto px-3 py-4" aria-label="Điều hướng di động">
                    {visibleGroups.map((group) => (
                      <div key={group.label} className="mb-5">
                        <p className="mb-1.5 px-3 text-[0.68rem] font-semibold uppercase tracking-[0.16em] text-emerald-50/35">
                          {group.label}
                        </p>
                        <div className="space-y-1">
                          {group.items.map((item) => (
                            <SidebarLink key={item.to} item={item} onClick={() => setMobileOpen(false)} />
                          ))}
                        </div>
                      </div>
                    ))}
                  </nav>
                  <div className="border-t border-white/8 p-4">
                    <Button
                      variant="ghost"
                      className="w-full justify-start text-emerald-50/70 hover:bg-white/10 hover:text-white"
                      onClick={() => {
                        setMobileOpen(false);
                        handleLogout();
                      }}
                    >
                      <LogOut className="mr-2 size-4" />
                      Đăng xuất
                    </Button>
                  </div>
                </SheetContent>
              </Sheet>

              <div className="min-w-0">
                <div className="flex items-center gap-1.5 text-xs text-muted-foreground">
                  <span className="hidden capitalize sm:inline">{todayLabel}</span>
                  <span className="hidden sm:inline">·</span>
                  <span>FitTrack</span>
                </div>
                <h1 className="truncate text-base font-semibold tracking-tight sm:text-lg">{currentPage}</h1>
              </div>
            </div>

            <div className="flex items-center gap-2">
              <NotificationBell isAdmin={isAdmin} />
              {location.pathname !== "/lunch" && canUseFeature(authUser, "lunchEnabled") && (
                <Button asChild variant="outline" className="hidden border-emerald-200 bg-emerald-50 text-emerald-800 hover:bg-emerald-100 sm:inline-flex">
                  <Link to="/lunch">
                    <Soup className="size-4" />
                    Xem menu trưa
                  </Link>
                </Button>
              )}
              <Link
                to="/profile"
                className="flex items-center gap-2 rounded-xl p-1.5 transition hover:bg-muted"
                aria-label="Mở hồ sơ"
              >
                <Avatar initials={initials} compact />
                <div className="hidden max-w-36 text-left md:block">
                  <p className="truncate text-xs font-semibold">{displayName}</p>
                  <p className="text-[0.65rem] text-muted-foreground">{isAdmin ? "Admin" : "Thành viên"}</p>
                </div>
                <ChevronRight className="hidden size-3.5 text-muted-foreground md:block" />
              </Link>
            </div>
          </div>
        </header>

        <main className="mx-auto w-full max-w-[1600px] px-4 py-5 sm:px-6 sm:py-7 lg:px-8 lg:py-8">
          <Outlet />
        </main>
      </div>
      {canUseFeature(authUser, "chatbotEnabled") && <AssistantChat />}
    </div>
  );
}

function Brand() {
  return (
    <Link to="/dashboard" className="flex items-center gap-3" aria-label="FitTrack - Tổng quan">
      <div className="grid size-10 place-items-center rounded-2xl bg-emerald-400 text-[#0c2821] shadow-lg shadow-black/15">
        <ChefHat className="size-5" />
      </div>
      <div>
        <p className="text-lg font-bold tracking-[-0.03em] text-white">FitTrack</p>
        <p className="text-[0.68rem] font-medium tracking-wide text-emerald-100/45">WELLNESS WORKSPACE</p>
      </div>
    </Link>
  );
}

function SidebarLink({ item, onClick }: { item: NavItem; onClick?: () => void }) {
  const Icon = item.icon;

  return (
    <NavLink
      to={item.to}
      end
      onClick={onClick}
      className={({ isActive }) =>
        [
          "group flex min-h-11 items-center gap-3 rounded-xl px-3 py-2 text-sm font-medium transition-all",
          isActive
            ? "bg-white text-[#0c2821] shadow-sm"
            : item.highlight
              ? "bg-emerald-400/12 text-emerald-100 hover:bg-emerald-400/20 hover:text-white"
              : "text-emerald-50/62 hover:bg-white/[0.07] hover:text-white",
        ].join(" ")
      }
    >
      {({ isActive }) => (
        <>
          <span
            className={[
              "grid size-8 shrink-0 place-items-center rounded-lg transition-colors",
              isActive
                ? "bg-emerald-100 text-emerald-800"
                : item.highlight
                  ? "bg-emerald-400/15 text-emerald-300"
                  : "bg-white/[0.05] text-emerald-50/65 group-hover:text-white",
            ].join(" ")}
          >
            <Icon className="size-4" />
          </span>
          <span className="min-w-0 flex-1 truncate">{item.label}</span>
          {item.highlight && !isActive && <span className="size-1.5 rounded-full bg-amber-300" />}
        </>
      )}
    </NavLink>
  );
}

function Avatar({ initials, compact = false }: { initials: string; compact?: boolean }) {
  return (
    <span
      className={[
        "grid shrink-0 place-items-center rounded-xl bg-gradient-to-br from-emerald-300 to-emerald-500 font-bold text-[#0c2821]",
        compact ? "size-8 text-[0.65rem]" : "size-9 text-xs",
      ].join(" ")}
      aria-hidden="true"
    >
      {initials}
    </span>
  );
}

function getInitials(name: string) {
  return name
    .trim()
    .split(/\s+/)
    .slice(-2)
    .map((part) => part.charAt(0).toUpperCase())
    .join("");
}
