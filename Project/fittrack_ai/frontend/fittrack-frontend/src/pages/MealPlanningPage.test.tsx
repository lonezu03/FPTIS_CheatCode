import { cleanup, fireEvent, render, screen, waitFor, within } from '@testing-library/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { afterEach, describe, expect, it, vi } from 'vitest';
import MealPlanningPage from './MealPlanningPage';
import { mondayOf } from '@/lib/meal-planning-dates';
import { ConfirmProvider } from '@/components/common/ConfirmDialog';
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
function mount() { const client = new QueryClient({ defaultOptions: { queries: { retry: false }, mutations: { retry: false } } }); return render(<QueryClientProvider client={client}><ConfirmProvider><MealPlanningPage /></ConfirmProvider></QueryClientProvider>); }

describe('Weekly meals', () => {
  afterEach(() => { cleanup(); vi.clearAllMocks(); });
  it('normalizes dates to Monday without changing the local day', () => { expect(mondayOf('2026-11-01')).toBe('2026-10-26'); });
  it('viewing plan and canceling consumption never writes diary', async () => {
    mount(); expect(await screen.findByText('Bữa thử')).toBeInTheDocument();
    expect(await screen.findByText(/31 bữa · 6200 kcal/)).toBeInTheDocument();
    fireEvent.click(screen.getByRole('button', { name: 'Đã ăn → ghi nhật ký' }));
    const dialog = await screen.findByRole('alertdialog');
    fireEvent.click(within(dialog).getByRole('button', { name: 'Hủy' }));
    await waitFor(() => expect(screen.queryByRole('alertdialog')).not.toBeInTheDocument());
    expect(consumePlannedMeal).not.toHaveBeenCalled();
    expect(savePlannedMeal).not.toHaveBeenCalled(); expect(listPlannedMeals).toHaveBeenCalled();
  });
  it('consumption requires confirmation and sends the exact plan/version', async () => {
    mount(); await screen.findByText('Bữa thử');
    fireEvent.click(screen.getByRole('button', { name: 'Đã ăn → ghi nhật ký' }));
    const dialog = await screen.findByRole('alertdialog');
    expect(dialog).toHaveTextContent('tính lại');
    expect(consumePlannedMeal).not.toHaveBeenCalled();
    fireEvent.click(within(dialog).getByRole('button', { name: 'Đã ăn, ghi nhật ký' }));
    await waitFor(() => expect(consumePlannedMeal).toHaveBeenCalledWith(expect.objectContaining({ id: 'plan', version: 3 })));
  });
});
