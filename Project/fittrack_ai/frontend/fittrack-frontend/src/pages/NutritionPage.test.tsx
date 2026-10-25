import { cleanup, fireEvent, render, screen, within } from "@testing-library/react";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { afterEach, describe, expect, it, vi } from "vitest";
import { MemoryRouter } from "react-router-dom";
import NutritionPage from "./NutritionPage";
import { createMealLog, getFoods, getNutritionDiary } from "../api/nutrition.api";

vi.mock("../api/nutrition.api", async (importOriginal) => ({
  ...await importOriginal<typeof import("../api/nutrition.api")>(),
  createMealLog: vi.fn(),
  getNutritionDiary: vi.fn().mockResolvedValue({
    date: "2026-10-07",
    status: "UNLOGGED",
    statusExplicit: false,
    consumed: { calories: 0, protein: 0, carbs: 0, fat: 0 },
    targets: { calories: 2000, protein: 100, carbs: 250, fat: 60 },
    remaining: { calories: 2000, protein: 100, carbs: 250, fat: 60 },
    waterMl: 0,
    waterTargetMl: 2100,
    meals: [],
  }),
  getFoods: vi.fn().mockResolvedValue([]),
  getNutritionConvenience: vi.fn().mockResolvedValue({
    recentFoods: [],
    favoriteFoods: [],
    savedMeals: [],
    recipes: [],
  }),
}));

describe("NutritionPage", () => {
  afterEach(cleanup);
  it("hiển thị nhật ký khi API tiện ích trả về dữ liệu rỗng đúng hợp đồng backend", async () => {
    const client = new QueryClient({ defaultOptions: { queries: { retry: false } } });
    render(
      <QueryClientProvider client={client}>
        <MemoryRouter><NutritionPage /></MemoryRouter>
      </QueryClientProvider>,
    );

    expect(await screen.findByText("Nước hôm nay")).toBeInTheDocument();
    expect(screen.getByText("Chưa ghi")).toBeInTheDocument();
  });

  it("sao chép bữa thành bản nháp có thể sửa, không tự ghi nhật ký", async () => {
    const original = await getNutritionDiary("2026-10-07");
    vi.mocked(getNutritionDiary).mockResolvedValue({ ...original, meals: [{ id: "previous", mealType: "BREAKFAST", logDate: "2026-10-06", totalCalories: 100, totalProtein: 5, totalCarbs: 10, totalFat: 2, createdAt: "2026-10-06T08:00:00", sourceType: "MANUAL", sourceId: null, readOnly: false, items: [{ id: "one", foodId: "rice", foodName: "Cơm", quantity: 2, servingAmount: 2, servingUnit: "SERVING", calories: 100, protein: 5, carbs: 10, fat: 2 }] }] });
    vi.mocked(getFoods).mockResolvedValue([{ id: "rice", name: "Cơm", calories: 50, protein: 2.5, carbs: 5, fat: 1, unit: "bát", custom: false, active: true }]);
    const client = new QueryClient({ defaultOptions: { queries: { retry: false } } });
    render(<QueryClientProvider client={client}><MemoryRouter><NutritionPage /></MemoryRouter></QueryClientProvider>);
    fireEvent.click(await screen.findByRole("button", { name: /Bữa sáng · 1 · 1 món/ }));
    const dialog = within(screen.getByRole("dialog"));
    const quantity = dialog.getByRole("spinbutton");
    expect(quantity).toHaveValue(2);
    fireEvent.change(quantity, { target: { value: "3" } });
    expect(quantity).toHaveValue(3);
    expect(dialog.getByRole("button", { name: "Lưu 1 món" })).toBeEnabled();
    expect(createMealLog).not.toHaveBeenCalled();
  });
});
