import { render, screen } from "@testing-library/react";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { describe, expect, it, vi } from "vitest";
import NutritionPage from "./NutritionPage";

vi.mock("../api/nutrition.api", async (importOriginal) => ({
  ...await importOriginal<typeof import("../api/nutrition.api")>(),
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
  it("hiển thị nhật ký khi API tiện ích trả về dữ liệu rỗng đúng hợp đồng backend", async () => {
    const client = new QueryClient({ defaultOptions: { queries: { retry: false } } });
    render(
      <QueryClientProvider client={client}>
        <NutritionPage />
      </QueryClientProvider>,
    );

    expect(await screen.findByText("Nước hôm nay")).toBeInTheDocument();
    expect(screen.getByText("Chưa ghi")).toBeInTheDocument();
  });
});
