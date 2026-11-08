import { describe, expect, it } from "vitest";
import type { AuthUser } from "@/store/auth.store";
import { findActive, navGroups, normalizeSearch, searchNav, visibleNavGroups } from "./navigation";
import { isNavPrefs, navPrefsKey, togglePinned } from "./navigation-prefs";

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
    expect(routes(visible)).toEqual(["/dashboard", "/finance", "/finance/savings", "/finance/shared", "/profile", "/reports/monthly"]);
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

  it("returns nothing for unknown terms", () => {
    expect(searchNav(all, "khong ton tai xyz")).toEqual([]);
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
