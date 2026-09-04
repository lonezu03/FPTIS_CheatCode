import { describe, expect, it } from "vitest";

import type { AuthUser } from "@/store/auth.store";
import { getAvailableGuideModuleIds } from "./user-guide-access";

const lunchOnlyUser: AuthUser = {
  userId: "user-1",
  email: "user@example.com",
  fullName: "Người dùng đặt cơm",
  role: "USER",
  lunchEnabled: true,
  fitnessEnabled: false,
  healthEnabled: false,
  chatbotEnabled: false,
  todoEnabled: false,
  scheduleEnabled: false,
  passwordChangeRequired: false,
};

describe("getAvailableGuideModuleIds", () => {
  it("chỉ trả hướng dẫn chung và Đặt cơm cho tài khoản lunch-only", () => {
    const ids = getAvailableGuideModuleIds(lunchOnlyUser, false);

    expect(ids).toContain("lunch");
    expect(ids).toContain("overview");
    expect(ids).toContain("notifications");
    expect(ids).toContain("profile");
    expect(ids).not.toContain("fitness");
    expect(ids).not.toContain("health");
    expect(ids).not.toContain("todos");
    expect(ids).not.toContain("schedule");
    expect(ids).not.toContain("assistant");
    expect(ids).not.toContain("admin");
  });

  it("cho admin xem toàn bộ hướng dẫn", () => {
    const admin = { ...lunchOnlyUser, role: "ADMIN" as const };
    const ids = getAvailableGuideModuleIds(admin, true);

    expect(ids).toEqual([
      "overview",
      "lunch",
      "todos",
      "schedule",
      "fitness",
      "health",
      "assistant",
      "notifications",
      "profile",
      "admin",
    ]);
  });
});
