import { useEffect, useMemo, useState } from "react";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { Link, Outlet, useLocation, useNavigate } from "react-router-dom";
import AppErrorBoundary from "./common/AppErrorBoundary";
import { getProfile } from "../api/user.api";
import { useAuthStore } from "../store/auth.store";
import { Button } from "@/components/ui/button";
import { Sheet, SheetContent, SheetHeader, SheetTitle, SheetTrigger } from "@/components/ui/sheet";
import { ChevronRight, CircleHelp, LogOut, Menu, Search, Soup } from "lucide-react";

import NotificationBell from "@/components/notifications/NotificationBell";
import AssistantChat from "@/components/assistant/AssistantChat";
import { canUseFeature } from "@/lib/feature-access";
import { logoutApi } from "@/api/auth.api";
import { UserGuideDialog } from "@/components/help/UserGuideDialog";
import { findActive, visibleNavGroups } from "@/lib/navigation";
import { useNavPrefs } from "@/lib/navigation-prefs";
import SidebarNav from "@/components/layout/SidebarNav";
import CommandPalette from "@/components/layout/CommandPalette";
import ModuleTabs from "@/components/layout/ModuleTabs";

export default function AppLayout() {
  const queryClient = useQueryClient();
  const logout = useAuthStore((state) => state.logout);
  const authUser = useAuthStore((state) => state.user);
  const navigate = useNavigate();
  const location = useLocation();
  const [mobileOpen, setMobileOpen] = useState(false);
  const [guideOpen, setGuideOpen] = useState(false);
  const [paletteOpen, setPaletteOpen] = useState(false);

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
        quoteEnabled: profile.quoteEnabled,
        financeEnabled: profile.financeEnabled,
        journalEnabled: profile.journalEnabled,
        passwordChangeRequired: profile.passwordChangeRequired,
      });
      return profile;
    },
    staleTime: 30_000,
    refetchInterval: 60_000,
    refetchOnWindowFocus: "always",
  });

  const isAdmin = (profileQuery.data?.role ?? authUser?.role) === "ADMIN";
  const guideUser = useMemo(() => {
    const profile = profileQuery.data;
    if (!authUser || !profile) return authUser;
    return {
      ...authUser,
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
      quoteEnabled: profile.quoteEnabled,
      financeEnabled: profile.financeEnabled,
      journalEnabled: profile.journalEnabled,
      passwordChangeRequired: profile.passwordChangeRequired,
    };
  }, [authUser, profileQuery.data]);
  const visibleGroups = useMemo(() => visibleNavGroups(authUser, isAdmin), [authUser, isAdmin]);
  const active = findActive(visibleGroups, location.pathname);
  const currentPage = active?.item.label ?? "AnCai";
  const { prefs, isOpen, hasExtraOpen, togglePin, toggleGroup, collapseAll } = useNavPrefs(authUser?.userId, active?.group.id ?? null);

  // Ctrl/⌘ + K opens the quick switcher from any page.
  useEffect(() => {
    const onKey = (event: KeyboardEvent) => {
      if ((event.ctrlKey || event.metaKey) && event.key.toLowerCase() === "k") {
        event.preventDefault();
        setMobileOpen(false);
        setPaletteOpen((value) => !value);
      }
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, []);

  const navProps = {
    groups: visibleGroups,
    activeGroupId: active?.group.id ?? null,
    prefs,
    isOpen,
    hasExtraOpen,
    onTogglePin: togglePin,
    onToggleGroup: toggleGroup,
    onCollapseAll: collapseAll,
  };
  const displayName = profileQuery.data?.fullName || authUser?.fullName || "Thành viên AnCai";
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

        <SidebarNav {...navProps} label="Điều hướng chính" />

        <div className="space-y-2 border-t border-white/8 p-3">
          <button
            type="button"
            onClick={() => setGuideOpen(true)}
            className="flex min-h-10 w-full items-center gap-3 rounded-xl px-3 text-sm font-medium text-emerald-50/70 transition hover:bg-white/[0.07] hover:text-white"
          >
            <CircleHelp className="size-4" />
            Hướng dẫn sử dụng
          </button>
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
          <div className="mx-auto flex h-[4.25rem] max-w-[1600px] items-center justify-between gap-2 px-3 sm:gap-4 sm:px-6 lg:px-8">
            <div className="flex min-w-0 items-center gap-3">
              <Sheet open={mobileOpen} onOpenChange={setMobileOpen}>
                <SheetTrigger asChild>
                  <Button variant="outline" size="icon" className="lg:hidden" aria-label="Mở menu">
                    <Menu className="size-5" />
                  </Button>
                </SheetTrigger>
                <SheetContent side="left" className="flex w-[19rem] max-w-[calc(100vw-2rem)] flex-col gap-0 border-none bg-[#0c2821] p-0 text-white">
                  <SheetHeader className="border-b border-white/8 px-5 py-5 text-left">
                    <SheetTitle>
                      <Brand />
                    </SheetTitle>
                  </SheetHeader>
                  <div className="flex min-h-0 flex-1 flex-col pt-3">
                    <SidebarNav {...navProps} label="Điều hướng di động" onNavigate={() => setMobileOpen(false)} />
                  </div>
                  <div className="border-t border-white/8 p-4">
                    <Button
                      variant="ghost"
                      className="mb-1 w-full justify-start text-emerald-50/70 hover:bg-white/10 hover:text-white"
                      onClick={() => {
                        setMobileOpen(false);
                        setGuideOpen(true);
                      }}
                    >
                      <CircleHelp className="mr-2 size-4" />
                      Hướng dẫn sử dụng
                    </Button>
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
                <div className="flex min-w-0 items-center gap-1.5 text-xs text-muted-foreground">
                  <span className="hidden capitalize xl:inline">{todayLabel}</span>
                  <span className="hidden xl:inline">·</span>
                  <span className="truncate">{active?.group.label ?? "AnCai"}</span>
                </div>
                <p className="truncate text-base font-semibold tracking-tight sm:text-lg">{currentPage}</p>
              </div>
            </div>

            <div className="flex shrink-0 items-center gap-1 sm:gap-2">
              <button
                type="button"
                onClick={() => setPaletteOpen(true)}
                className="hidden h-10 w-56 items-center gap-2 rounded-xl border border-input bg-background px-3 text-sm text-muted-foreground transition hover:border-ring/50 hover:text-foreground md:flex xl:w-72"
              >
                <Search className="size-4" aria-hidden="true" />
                <span className="flex-1 text-left">Tìm chức năng…</span>
                <kbd className="rounded-md border bg-muted px-1.5 py-0.5 text-[0.65rem] font-medium">Ctrl K</kbd>
              </button>
              <Button type="button" variant="outline" size="icon" className="md:hidden" onClick={() => setPaletteOpen(true)} aria-label="Tìm chức năng">
                <Search className="size-4" />
              </Button>
              <Button
                type="button"
                variant="outline"
                size="icon"
                onClick={() => setGuideOpen(true)}
                aria-label="Mở hướng dẫn sử dụng"
                title="Hướng dẫn sử dụng"
              >
                <CircleHelp className="size-4" />
              </Button>
              <NotificationBell />
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
          {active && <ModuleTabs group={active.group} />}
          <AppErrorBoundary key={location.pathname} contained><Outlet /></AppErrorBoundary>
        </main>
      </div>
      {canUseFeature(authUser, "chatbotEnabled") && <AssistantChat />}
      <CommandPalette open={paletteOpen} onOpenChange={setPaletteOpen} groups={visibleGroups} pinned={prefs.pinned} />
      <UserGuideDialog
        open={guideOpen}
        onOpenChange={setGuideOpen}
        user={guideUser}
        isAdmin={isAdmin}
      />
    </div>
  );
}

function Brand() {
  return (
    <Link to="/dashboard" className="flex items-center gap-3" aria-label="AnCai - Tổng quan">
      <img
        src="/branding/fittrack-logo.png"
        alt="Logo AnCai"
        className="size-11 rounded-2xl object-cover shadow-lg shadow-black/15"
      />
      <div>
        <p className="text-lg font-bold tracking-[-0.03em] text-white">AnCai</p>
        <p className="text-[0.68rem] font-medium tracking-wide text-emerald-100/45">WELLNESS WORKSPACE</p>
      </div>
    </Link>
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
