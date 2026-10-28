import { cleanup, fireEvent, render, screen, waitFor } from '@testing-library/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { afterEach, describe, expect, it, vi } from 'vitest';
import MealPlanningPage from './MealPlanningPage';
import { mondayOf } from '@/lib/meal-planning-dates';
import { consumePlannedMeal, listPlannedMeals, savePlannedMeal } from '@/api/meal-planning.api';

vi.mock('@/api/meal-planning.api', () => ({
  listPlannedMeals: vi.fn().mockResolvedValue({ content: [{ id: 'plan', version: 3, date: '2020-01-06', mealType: 'BREAKFAST', name: 'Bữa thử', notes: null, items: [{ foodId: 'rice', foodName: 'Cơm', servingAmount: 1, servingUnit: 'SERVING' }], totals: { calories: 200, protein: 5, carbs: 40, fat: 1, knownMicronutrientValues: 0, possibleMicronutrientValues: 8 }, loggedMealId: null }], totalElements: 1, totalPages: 1, last: true }),
  getGroceries: vi.fn().mockResolvedValue({ version: 0, items: [] }), savePlannedMeal: vi.fn().mockResolvedValue({}), consumePlannedMeal: vi.fn().mockResolvedValue({}),
  getMealWeekSummary: vi.fn().mockResolvedValue({ plannedMealCount: 31, totals: { calories: 6200, protein: 310, carbs: 620, fat: 124, knownMicronutrientValues: 0, possibleMicronutrientValues: 248 } }),
  removePlannedMeal: vi.fn(), copyMealWeek: vi.fn(), addGrocery: vi.fn(), checkGrocery: vi.fn(), deleteGrocery: vi.fn(), regenerateGroceries: vi.fn(),
}));
vi.mock('@/api/nutrition.api', () => ({
  getNutritionConvenience: vi.fn().mockResolvedValue({ savedMeals: [], recipes: [] }),
  searchNutritionFoods: vi.fn().mockResolvedValue({ content: [{ id: 'rice', name: 'Cơm', unit: 'bát' }], last: true }),
}));
function mount() { const client = new QueryClient({ defaultOptions: { queries: { retry: false }, mutations: { retry: false } } }); return render(<QueryClientProvider client={client}><MealPlanningPage /></QueryClientProvider>); }

describe('Weekly meals', () => {
  afterEach(() => { cleanup(); vi.clearAllMocks(); });
  it('normalizes dates to Monday without changing the local day', () => { expect(mondayOf('2026-11-01')).toBe('2026-10-26'); });
  it('viewing plan and canceling consumption never writes diary', async () => {
    mount(); expect(await screen.findByText('Bữa thử')).toBeInTheDocument();
    expect(await screen.findByText(/31 bữa · 6200 kcal/)).toBeInTheDocument();
    const confirm = vi.spyOn(window, 'confirm').mockReturnValue(false);
    fireEvent.click(screen.getByRole('button', { name: 'Đã ăn → ghi nhật ký' }));
    expect(consumePlannedMeal).not.toHaveBeenCalled();
    expect(savePlannedMeal).not.toHaveBeenCalled(); expect(listPlannedMeals).toHaveBeenCalled(); confirm.mockRestore();
  });
  it('consumption requires confirmation and sends the exact plan/version', async () => {
    mount(); await screen.findByText('Bữa thử');
    const confirm = vi.spyOn(window, 'confirm').mockReturnValue(true);
    fireEvent.click(screen.getByRole('button', { name: 'Đã ăn → ghi nhật ký' }));
    await waitFor(() => expect(consumePlannedMeal).toHaveBeenCalledWith(expect.objectContaining({ id: 'plan', version: 3 })));
    expect(confirm.mock.calls[0][0]).toContain('tính lại'); confirm.mockRestore();
  });
});
