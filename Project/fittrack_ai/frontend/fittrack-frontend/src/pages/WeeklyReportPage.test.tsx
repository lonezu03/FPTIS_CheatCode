import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { cleanup, fireEvent, render, screen } from "@testing-library/react";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { MemoryRouter } from "react-router-dom";
import WeeklyReportPage from "./WeeklyReportPage";
import { getWeeklyReport, type WeeklyReport } from "@/api/report.api";
import { getCurrentWeeklyCheckIn, getWeeklyRecommendations } from "@/api/recommendation.api";

vi.mock("sonner", () => ({ toast: { success: vi.fn(), error: vi.fn() } }));
vi.mock("@/api/report.api", () => ({ getWeeklyReport: vi.fn() }));
vi.mock("@/api/recommendation.api", () => ({
  getWeeklyRecommendations: vi.fn(),
  getCurrentWeeklyCheckIn: vi.fn(),
  decideWeeklyCheckIn: vi.fn(),
}));
// Recharts đo kích thước bằng ResizeObserver, jsdom không có; biểu đồ không phải đối tượng kiểm thử ở đây.
vi.mock("recharts", async (importOriginal) => {
  const actual = await importOriginal<typeof import("recharts")>();
  return { ...actual, ResponsiveContainer: () => null };
});

const report: WeeklyReport = {
  fromDate: "2026-11-19", toDate: "2026-11-25", periodDays: 7, completeNutritionDays: 6, partialNutritionDays: 1,
  unloggedNutritionDays: 0, nutritionConfidencePercent: 86, nutritionDataSufficient: true, averageCalories: 2100,
  averageProtein: 120, averageCarbs: 250, averageFat: 70, targetCalories: 2200, targetProtein: 130, targetCarbs: 260,
  targetFat: 70, totalMeals: 18, totalWorkouts: 4, workoutDays: 4, startWeight: 70, endWeight: 69.6, weightChange: -0.4,
  startWaist: null, endWaist: null, waistChange: null, caloriesCompliancePercent: 95, proteinCompliancePercent: 92,
  insights: [], dailyNutrition: [],
};

function show() {
  render(
    <QueryClientProvider client={new QueryClient({ defaultOptions: { queries: { retry: false } } })}>
      <MemoryRouter><WeeklyReportPage /></MemoryRouter>
    </QueryClientProvider>,
  );
}

beforeEach(() => {
  vi.mocked(getWeeklyReport).mockResolvedValue(report);
  vi.mocked(getCurrentWeeklyCheckIn).mockRejectedValue(new Error("no check-in"));
});
afterEach(() => { cleanup(); vi.clearAllMocks(); });

describe("WeeklyReportPage recommendations", () => {
  it("shows an error with retry instead of an endless skeleton when recommendations fail", async () => {
    vi.mocked(getWeeklyRecommendations)
      .mockRejectedValueOnce(new Error("down"))
      .mockResolvedValueOnce({
        fromDate: report.fromDate, toDate: report.toDate, summary: "Tuần ổn định", nutritionDataSufficient: true,
        completeNutritionDays: 6, periodDays: 7, nutritionConfidencePercent: 86, recommendations: [],
      });
    show();

    expect(await screen.findByText("Không thể tải khuyến nghị")).toBeInTheDocument();
    expect(screen.queryByRole("status", { name: "Đang tải khuyến nghị" })).not.toBeInTheDocument();

    fireEvent.click(screen.getByRole("button", { name: "Thử lại" }));

    expect(await screen.findByText("Chưa có khuyến nghị")).toBeInTheDocument();
    expect(screen.queryByText("Không thể tải khuyến nghị")).not.toBeInTheDocument();
    expect(getWeeklyRecommendations).toHaveBeenCalledTimes(2);
  });
});
