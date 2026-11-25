import type { BrowserContext, Request, Route } from "@playwright/test";

/**
 * In-memory fake of the AnCai API for smoke tests against a production build.
 *
 * Only paths that start with /api/ are intercepted (never the `**\/api/**` glob,
 * which also matches /src/api/* modules served by the Vite dev server).
 * The fake keeps a "refresh cookie" flag: login sets it, logout clears it and
 * /api/auth/refresh answers 401 while it is unset, like the real backend.
 */

export const TEST_EMAIL = "an.nguyen@example.invalid";
export const TEST_PASSWORD = "MatKhau@2026";

const USER_ID = "7d2f0c4e-5a1b-4c3d-9e8f-0a1b2c3d4e5f";

/** Account with Todo + Finance enabled; other modules are off to keep the page set small. */
export const smokeUser = {
  userId: USER_ID,
  email: TEST_EMAIL,
  fullName: "Nguyễn Văn An",
  role: "USER" as const,
  lunchEnabled: false,
  fitnessEnabled: false,
  healthEnabled: false,
  chatbotEnabled: false,
  todoEnabled: true,
  scheduleEnabled: false,
  quoteEnabled: false,
  financeEnabled: true,
  journalEnabled: false,
  passwordChangeRequired: false,
};

const authResponse = () => ({ token: "smoke-access-token", tokenType: "Bearer", ...smokeUser });

const profile = () => ({
  id: USER_ID,
  email: smokeUser.email,
  fullName: smokeUser.fullName,
  role: smokeUser.role,
  lunchEnabled: smokeUser.lunchEnabled,
  fitnessEnabled: smokeUser.fitnessEnabled,
  healthEnabled: smokeUser.healthEnabled,
  chatbotEnabled: smokeUser.chatbotEnabled,
  todoEnabled: smokeUser.todoEnabled,
  scheduleEnabled: smokeUser.scheduleEnabled,
  quoteEnabled: smokeUser.quoteEnabled,
  financeEnabled: smokeUser.financeEnabled,
  journalEnabled: smokeUser.journalEnabled,
  passwordChangeRequired: false,
  assistantConsent: false,
  emailNotificationsEnabled: true,
  gender: "MALE",
  age: 29,
  height: 170,
  weight: 65,
  goal: "MAINTAIN",
  activityLevel: "MODERATE",
  bmr: 1610,
  tdee: 2490,
  targetCalories: 2490,
  targetProtein: 130,
  targetCarbs: 300,
  targetFat: 80,
});

const today = () => new Date().toISOString().slice(0, 10);

const dashboardToday = () => ({
  date: today(),
  totalCalories: 0,
  totalProtein: 0,
  totalCarbs: 0,
  totalFat: 0,
  targetCalories: 2490,
  targetProtein: 130,
  targetCarbs: 300,
  targetFat: 80,
  caloriesProgressPercent: 0,
  proteinProgressPercent: 0,
  carbsProgressPercent: 0,
  fatProgressPercent: 0,
  mealCount: 0,
  workoutCount: 0,
  lunchEnabled: smokeUser.lunchEnabled,
  fitnessEnabled: smokeUser.fitnessEnabled,
  healthEnabled: smokeUser.healthEnabled,
  todoEnabled: smokeUser.todoEnabled,
  scheduleEnabled: smokeUser.scheduleEnabled,
  quoteEnabled: smokeUser.quoteEnabled,
  financeEnabled: smokeUser.financeEnabled,
  journalEnabled: smokeUser.journalEnabled,
  latestWorkoutNote: null,
  remainingCalories: 2490,
  remainingProtein: 130,
  openTodoCount: 2,
  scheduleCount: 0,
  agenda: [
    {
      sourceId: "c1a2b3c4-0000-4000-8000-000000000001",
      sourceType: "TODO",
      title: "Nộp báo cáo chi phí tháng",
      category: "WORK",
      startAt: `${today()}T09:00:00`,
      endAt: null,
      status: "OPEN",
    },
  ],
  coachInsight: null,
  coachActionPath: null,
});

const walletAccount = {
  id: "a0000000-0000-4000-8000-000000000001",
  name: "Ví tiền mặt",
  accountType: "CASH",
  currencyCode: "VND",
  openingBalance: 2000000,
  balance: 3250000,
  archived: false,
};

const financeDashboard = (month: string) => ({
  month,
  totalBalance: 3250000,
  income: 15000000,
  expense: 4200000,
  netSaving: 10800000,
  savingRate: 72,
  mandatoryCommitted: 3000000,
  mandatoryPaid: 2500000,
  mandatoryRemaining: 500000,
  savingCommitted: 2000000,
  trueExpensePreparation: 300000,
  flexibleAvailable: 1750000,
  accounts: [walletAccount],
  budgets: [],
  upcoming: [],
  topCategories: [],
  natureBreakdown: [],
  insight: "Chi tiêu linh hoạt đang trong ngưỡng an toàn.",
});

export const SAVINGS_GOAL_TITLE = "Quỹ dự phòng 6 tháng";

const savingsPage = () => ({
  content: [
    {
      id: "5a000000-0000-4000-8000-000000000001",
      title: SAVINGS_GOAL_TITLE,
      target: 60000000,
      progress: 18000000,
      currencyCode: "VND",
      targetDate: "2027-06-30",
      note: "Gửi mỗi tháng 3 triệu",
      archived: false,
      version: 3,
    },
  ],
  page: 0,
  totalPages: 1,
  totalElements: 1,
});

export type MockApiState = {
  /** True while the fake refresh cookie is valid. */
  session: boolean;
  /** Paths (exact) that answer 401 for the current access token. */
  unauthorizedPaths: Set<string>;
  /** Every intercepted request, for assertions. */
  calls: { method: string; path: string; body: unknown }[];
};

export async function installApiMock(context: BrowserContext, options: { loggedIn?: boolean } = {}): Promise<MockApiState> {
  const state: MockApiState = { session: options.loggedIn ?? false, unauthorizedPaths: new Set(), calls: [] };

  await context.route(
    (url) => new URL(url).pathname.startsWith("/api/"),
    async (route: Route, request: Request) => {
      const url = new URL(request.url());
      const path = url.pathname;
      const method = request.method();
      let body: unknown;
      try {
        body = request.postDataJSON();
      } catch {
        body = request.postData();
      }
      state.calls.push({ method, path, body });

      const json = (data: unknown, status = 200) => route.fulfill({ status, json: data });
      const unauthorized = () => json({ status: 401, message: "Phiên đăng nhập đã hết hạn" }, 401);

      if (path === "/api/auth/refresh") {
        return state.session ? json(authResponse()) : unauthorized();
      }
      if (path === "/api/auth/login" && method === "POST") {
        const credentials = body as { email?: string; password?: string } | null;
        if (credentials?.email === TEST_EMAIL && credentials.password === TEST_PASSWORD) {
          state.session = true;
          return json(authResponse());
        }
        return json({ status: 401, message: "Email hoặc mật khẩu không đúng." }, 401);
      }
      if (path === "/api/auth/logout") {
        state.session = false;
        return route.fulfill({ status: 204 });
      }

      if (state.unauthorizedPaths.has(path)) return unauthorized();

      if (method === "GET") {
        switch (path) {
          case "/api/users/me":
            return json(profile());
          case "/api/notifications":
            return json({ unreadCount: 0, notifications: [] });
          case "/api/dashboard/today":
            return json(dashboardToday());
          case "/api/dashboard/progress":
            return json({ points: [] });
          case "/api/finance/dashboard":
            return json(financeDashboard(url.searchParams.get("month") ?? `${today().slice(0, 7)}-01`));
          case "/api/finance/accounts":
            return json([walletAccount]);
          case "/api/finance/savings":
            return json(savingsPage());
          case "/api/finance/transactions": {
            const size = Number(url.searchParams.get("size") ?? 20);
            return json({ content: [], page: 0, size, totalElements: 0, totalPages: 0, first: true, last: true });
          }
          default:
            // Pages not covered here only need an empty, successful answer.
            return json([]);
        }
      }

      // Smoke tests never expect writes besides auth; acknowledge them without data.
      return json({});
    },
  );

  return state;
}
