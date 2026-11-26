import { describe, expect, it } from "vitest";
import type { AuthUser } from "@/store/auth.store";
import appRoutesSource from "@/routes/AppRoutes.tsx?raw";
import { findActive, navCommands, navGroups, normalizeSearch, searchAll, searchNav, visibleNavGroups } from "./navigation";
import { isNavPrefs, navPrefsKey, togglePinned } from "./navigation-prefs";
import { searchCases } from "./navigation-search-cases";

const user = (overrides: Partial<AuthUser> = {}) =>
  ({
    userId: "u1",
    email: "a@example.invalid",
    fullName: "A",
    role: "USER",
    lunchEnabled: false,
    fitnessEnabled: false,
    healthEnabled: false,
    chatbotEnabled: false,
    todoEnabled: false,
    scheduleEnabled: false,
    quoteEnabled: false,
    financeEnabled: false,
    journalEnabled: false,
    passwordChangeRequired: false,
    ...overrides,
  }) as AuthUser;

const routes = (groups: ReturnType<typeof visibleNavGroups>) => groups.flatMap((group) => group.items.map((item) => item.to));

describe("navigation config", () => {
  it("keeps every route unique", () => {
    const all = navGroups.flatMap((group) => group.items.map((item) => item.to));
    expect(new Set(all).size).toBe(all.length);
  });

  it("shows only the modules the account may use and hides empty groups", () => {
    const visible = visibleNavGroups(user({ financeEnabled: true }), false);
    expect(routes(visible)).toEqual(["/dashboard", "/finance", "/finance/savings", "/finance/shared", "/music", "/music/guitar", "/music/flute", "/music/tools", "/profile", "/reports/monthly"]);
    expect(visible.map((group) => group.id)).not.toContain("admin");
  });

  it("requires both health and finance for purchase prices", () => {
    expect(routes(visibleNavGroups(user({ healthEnabled: true }), false))).not.toContain("/purchase-prices");
    expect(routes(visibleNavGroups(user({ healthEnabled: true, financeEnabled: true }), false))).toContain("/purchase-prices");
  });

  it("gives admins every module including administration", () => {
    const visible = visibleNavGroups(user({ role: "ADMIN" }), true);
    expect(routes(visible)).toHaveLength(navGroups.flatMap((group) => group.items).length);
  });
});

describe("searchNav", () => {
  const all = visibleNavGroups(user({ role: "ADMIN" }), true);

  it("ignores Vietnamese accents and case", () => {
    expect(normalizeSearch("  Tài   CHÍNH đặt ")).toBe("tai chinh dat");
    expect(searchNav(all, "tiet kiem")[0].item.to).toBe("/finance/savings");
    expect(searchNav(all, "ĐẶT CƠM")[0].item.to).toBe("/lunch");
  });

  it("matches by keywords and group names, ranking label prefixes first", () => {
    expect(searchNav(all, "pomodoro").map((match) => match.item.to)).toEqual(["/focus"]);
    expect(searchNav(all, "giao an")[0].item.to).toBe("/workout-plans");
    expect(searchNav(all, "luyen tap").length).toBeGreaterThanOrEqual(6);
  });

  it("finds the music pages without accents", () => {
    const routesFor = (query: string) => searchNav(all, query).map((match) => match.item.to);
    expect(routesFor("ghi ta")[0]).toBe("/music/guitar");
    expect(routesFor("guitar")).toContain("/music/guitar");
    expect(routesFor("sao")[0]).toBe("/music/flute");
    expect(routesFor("metronome")).toEqual(["/music/tools"]);
    expect(routesFor("chinh day")).toContain("/music/tools");
    expect(routesFor("nhac")).toEqual(expect.arrayContaining(["/music", "/music/guitar", "/music/flute", "/music/tools"]));
    expect(routesFor("dan")).toContain("/music/guitar");
    // Visible to every account, no module flag needed.
    expect(routes(visibleNavGroups(user(), false))).toContain("/music");
  });

  it("returns nothing for unknown terms", () => {
    expect(searchNav(all, "xyz qwerty")).toEqual([]);
    expect(searchAll(all, "zzzz")).toEqual([]);
  });

  it("normalizes đ/Đ, punctuation and extra spaces", () => {
    expect(normalizeSearch("ĐĂNG   xuất!!")).toBe("dang xuat");
    expect(normalizeSearch("Thu-chi, ngân_sách")).toBe("thu chi ngan sach");
  });

  it("tolerates word prefixes, words typed together and small typos", () => {
    expect(searchNav(all, "pomodor")[0].item.to).toBe("/focus");
    expect(searchNav(all, "datcom")[0].item.to).toBe("/lunch");
    expect(searchNav(all, "guiter")[0].item.to).toBe("/music/guitar");
    // Typo matches are only a fallback: exact words win.
    expect(searchNav(all, "tien")[0].item.to).toBe("/finance");
  });

  it.each(searchCases)("finds $expect for “$query”", ({ query, expect: wanted, top = 3 }) => {
    const found = searchAll(all, query).map((result) => (result.kind === "page" ? result.item.to : `cmd:${result.command.id}`));
    expect(found.slice(0, top)).toContain(wanted);
  });

  it("covers at least 80 realistic queries", () => {
    expect(searchCases.length).toBeGreaterThanOrEqual(80);
  });

  it("offers account actions only when searching", () => {
    expect(searchAll(all, "").every((result) => result.kind === "page")).toBe(true);
    expect(navCommands.map((command) => command.id)).toEqual(expect.arrayContaining(["logout", "help", "change-password"]));
  });
});

describe("routes", () => {
  const registered = new Set([...appRoutesSource.matchAll(/path="([^"]+)"/g)].map((match) => match[1]));

  it("registers every menu page and command route in AppRoutes", () => {
    const targets = [...navGroups.flatMap((group) => group.items.map((item) => item.to)), ...navCommands.flatMap((command) => (command.to ? [command.to] : []))];
    expect(targets.filter((to) => !registered.has(to))).toEqual([]);
  });

  it("lists every user-facing page in the menu", () => {
    const menu = new Set(navGroups.flatMap((group) => group.items.map((item) => item.to)));
    // Auth screens and the catch-all live outside the menu on purpose.
    const outside = new Set(["/login", "/verify-email", "/forgot-password", "/reset-password", "/change-password", "*"]);
    expect([...registered].filter((path) => !menu.has(path) && !outside.has(path))).toEqual([]);
  });

  it("shows a not-found page instead of silently redirecting unknown addresses", () => {
    expect(appRoutesSource).toMatch(/path="\*" element={<NotFoundPage \/>}/);
  });
});

describe("findActive", () => {
  const all = visibleNavGroups(user({ role: "ADMIN" }), true);

  it("prefers the longest matching route", () => {
    expect(findActive(all, "/finance/savings")?.item.to).toBe("/finance/savings");
    expect(findActive(all, "/finance")?.group.id).toBe("finance");
    expect(findActive(all, "/reports/weekly")?.group.id).toBe("health");
    expect(findActive(all, "/unknown")).toBeNull();
  });
});

describe("navigation prefs", () => {
  it("validates stored data and scopes the key per account", () => {
    expect(isNavPrefs({ pinned: ["/todos"], open: [] })).toBe(true);
    expect(isNavPrefs({ pinned: [1], open: [] })).toBe(false);
    expect(navPrefsKey("u1")).toBe("fittrack:nav:u1");
    expect(navPrefsKey(null)).toBeNull();
  });

  it("toggles pins and keeps at most eight", () => {
    expect(togglePinned(["/a"], "/a")).toEqual([]);
    const many = Array.from({ length: 8 }, (_, index) => `/p${index}`);
    expect(togglePinned(many, "/new")).toEqual([...many.slice(1), "/new"]);
  });
});
