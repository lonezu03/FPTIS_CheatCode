import { cleanup, fireEvent, render, screen, within, waitFor } from "@testing-library/react";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { afterEach, describe, expect, it, vi } from "vitest";
import { MemoryRouter } from "react-router-dom";
import NutritionPage from "./NutritionPage";
import { analyzeFoodPhoto, createMealLog, searchNutritionFoods, getNutritionFood, getNutritionDiary } from "../api/nutrition.api";

vi.mock("../api/nutrition.api", async (importOriginal) => ({
  ...await importOriginal<typeof import("../api/nutrition.api")>(),
  createMealLog: vi.fn(),
  analyzeFoodPhoto: vi.fn(),
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
  searchNutritionFoods: vi.fn().mockResolvedValue({ content: [], page: 0, size: 20, totalPages: 1, totalElements: 0, first: true, last: true }),
  getNutritionFood: vi.fn(),
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
    vi.mocked(getNutritionFood).mockResolvedValue({ id: "rice", name: "Cơm", calories: 50, protein: 2.5, carbs: 5, fat: 1, unit: "bát", custom: false, active: true });
    const client = new QueryClient({ defaultOptions: { queries: { retry: false } } });
    render(<QueryClientProvider client={client}><MemoryRouter><NutritionPage /></MemoryRouter></QueryClientProvider>);
    fireEvent.click(await screen.findByRole("button", { name: /Bữa sáng · 1 · 1 món/ }));
    const dialog = within(screen.getByRole("dialog"));
    const quantity = dialog.getByRole("spinbutton");
    expect(quantity).toHaveValue(2);
    fireEvent.change(quantity, { target: { value: "3" } });
    expect(quantity).toHaveValue(3);
    await waitFor(() => expect(dialog.getByRole("button", { name: "Lưu 1 món" })).toBeEnabled());
    expect(getNutritionFood).toHaveBeenCalledWith('rice');
    expect(searchNutritionFoods).toHaveBeenCalled();
    expect(createMealLog).not.toHaveBeenCalled();
  });

  it("ảnh ước tính gram cho món ml chỉ tạo 1 khẩu phần và không gửi GRAM", async () => {
    vi.mocked(createMealLog).mockClear();
    const milk = { id: 'milk', name: 'Sữa thử', calories: 60, protein: 3, carbs: 4, fat: 3, unit: '100ml', servingSizeGrams: 100, custom: false, active: true };
    const original = await getNutritionDiary('2026-10-07');
    vi.mocked(getNutritionDiary).mockResolvedValue({ ...original, meals: [] });
    vi.mocked(searchNutritionFoods).mockResolvedValue({ content: [milk], page: 0, size: 20, totalPages: 1, totalElements: 1, first: true, last: true });
    vi.mocked(getNutritionFood).mockResolvedValue(milk);
    vi.mocked(analyzeFoodPhoto).mockResolvedValue({ items: [{ name: milk.name, estimatedGrams: 150, calories: 90, protein: null, carbs: null, fat: null }], note: 'Ước tính tham khảo', requiresConfirmation: true });
    vi.mocked(createMealLog).mockResolvedValue({ id: 'new', mealType: 'BREAKFAST', logDate: '2026-10-07', totalCalories: 60, totalProtein: 3, totalCarbs: 4, totalFat: 3, createdAt: '', sourceType: 'MANUAL', sourceId: null, readOnly: false, items: [] });
    const client = new QueryClient({ defaultOptions: { queries: { retry: false } } });
    const { container } = render(<QueryClientProvider client={client}><MemoryRouter initialEntries={['/nutrition?action=new']}><NutritionPage /></MemoryRouter></QueryClientProvider>);
    await screen.findByRole('dialog');
    const fileInput = container.ownerDocument.querySelector('input[type="file"]')!;
    fireEvent.change(fileInput, { target: { files: [new File(['photo'], 'milk.jpg', { type: 'image/jpeg' })] } });
    const addMatches = await screen.findByRole('button', { name: 'Thêm món đã chọn vào bản nháp' });
    await waitFor(() => expect(addMatches).toBeEnabled());
    fireEvent.click(addMatches);
    const dialog = within(screen.getByRole('dialog'));
    expect(dialog.getByText(/Ảnh chỉ ước tính gram, không quy đổi thành ml/)).toBeInTheDocument();
    expect(dialog.getByRole('spinbutton')).toHaveValue(1);
    const save = dialog.getByRole('button', { name: 'Lưu 1 món' });
    await waitFor(() => expect(save).toBeEnabled());
    fireEvent.click(save);
    await waitFor(() => expect(createMealLog).toHaveBeenCalledWith(expect.objectContaining({ items: [{ foodId: 'milk', quantity: 1, servingAmount: 1, servingUnit: 'SERVING' }] })));
  });
});
