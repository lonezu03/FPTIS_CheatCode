import { cleanup, fireEvent, render, screen, waitFor, within } from '@testing-library/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { MemoryRouter } from 'react-router-dom';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import DashboardPage from './DashboardPage';
import { useAuthStore, type AuthUser } from '@/store/auth.store';
import { completeTodo, getTodos } from '@/api/todo.api';
import { getFinanceDashboard, getFinanceTransactions } from '@/api/finance.api';
import { getNutritionDiary } from '@/api/nutrition.api';
import { personalTrackingApi } from '@/api/personaltracking.api';
import { trainingAppointments } from '@/api/training-program.api';
import api from '@/api/axios';

vi.mock('@/api/axios', () => ({ default: { get: vi.fn(), post: vi.fn(), put: vi.fn(), patch: vi.fn(), delete: vi.fn() } }));
vi.mock('@/api/dashboard.api', () => ({
  getTodayDashboard: vi.fn().mockResolvedValue({ workoutCount: 0, coachInsight: null, totalCalories: 0, targetCalories: 2000 }),
  getProgressDashboard: vi.fn().mockResolvedValue({ points: [] }),
}));
vi.mock('@/api/achievement.api', () => ({ getAchievementSummary: vi.fn().mockResolvedValue(null) }));
vi.mock('@/api/todo.api', () => ({ getTodos: vi.fn(), completeTodo: vi.fn(), createTodo: vi.fn() }));
vi.mock('@/api/finance.api', () => ({
  getFinanceDashboard: vi.fn(), getFinanceTransactions: vi.fn(),
  getFinanceAccounts: vi.fn().mockResolvedValue([]), getFinanceCategories: vi.fn().mockResolvedValue([]), createFinanceTransaction: vi.fn(),
}));
vi.mock('@/api/nutrition.api', () => ({
  getNutritionDiary: vi.fn(), updateNutritionDayStatus: vi.fn(),
  getNutritionConvenience: vi.fn().mockResolvedValue({ recentFoods: [], favoriteFoods: [], savedMeals: [], recipes: [] }),
  searchNutritionFoods: vi.fn().mockResolvedValue({ content: [] }), createMealLog: vi.fn(),
}));
vi.mock('@/api/personaltracking.api', () => ({ personalTrackingApi: { list: vi.fn(), checkin: vi.fn() } }));
vi.mock('@/api/training-program.api', () => ({ trainingAppointments: vi.fn() }));
vi.mock('../components/MacroProgressCard', () => ({ default: () => null }));
vi.mock('../components/DeferredFitnessTrendCharts', () => ({ default: () => null }));
vi.mock('../components/quotes/DailyQuoteCard', () => ({ default: () => null }));

const flags = { lunchEnabled: false, fitnessEnabled: false, healthEnabled: false, chatbotEnabled: false, todoEnabled: false, scheduleEnabled: false, quoteEnabled: false, financeEnabled: false, journalEnabled: false };
const todo = (id: string, title: string, extra: Record<string, unknown> = {}) => ({ id, title, status: 'OPEN', priority: 'MEDIUM', dueAt: null, startAt: null, completedAt: null, ...extra });

function show(user: Partial<AuthUser>) {
  useAuthStore.setState({ user: { userId: 'test', role: 'USER', fullName: 'Nguyễn An', ...flags, ...user } as AuthUser });
  render(<QueryClientProvider client={new QueryClient({ defaultOptions: { queries: { retry: false } } })}><MemoryRouter><DashboardPage /></MemoryRouter></QueryClientProvider>);
}

beforeEach(() => {
  vi.mocked(getTodos).mockResolvedValue([
    todo('t1', 'Nộp báo cáo', { dueAt: '2000-01-01T09:00:00' }),
    todo('t2', 'Đi chợ'),
  ] as never);
  vi.mocked(completeTodo).mockResolvedValue(todo('t2', 'Đi chợ', { status: 'DONE' }) as never);
  vi.mocked(getFinanceDashboard).mockResolvedValue({ expense: 1_500_000, flexibleAvailable: 500_000, budgets: [] } as never);
  vi.mocked(getFinanceTransactions).mockResolvedValue({ content: [
    { type: 'EXPENSE', status: 'POSTED', amount: 50_000 }, { type: 'EXPENSE', status: 'VOID', amount: 90_000 },
  ] } as never);
  vi.mocked(getNutritionDiary).mockResolvedValue({ status: 'PARTIAL', consumed: { calories: 500 }, targets: { calories: 2000 }, meals: [
    { id: 'm1', mealType: 'BREAKFAST', totalCalories: 500 },
  ] } as never);
  vi.mocked(personalTrackingApi.list).mockResolvedValue({ content: [
    { id: 'h1', title: 'Uống nước', archived: false, startDate: '2000-01-01' },
    { id: 'h2', title: 'Đọc sách', archived: false, startDate: '2000-01-01' },
  ], totalElements: 2 } as never);
  vi.mocked(personalTrackingApi.checkin).mockResolvedValue({} as never);
  vi.mocked(api.get).mockImplementation(async (url: string) => ({
    data: { cells: [{ day: 'x', status: url.includes('h1') ? 'PENDING' : 'DONE', scheduled: true }] },
  }));
  vi.mocked(trainingAppointments).mockResolvedValue([{ id: 'a1', title: 'Ngực + tay sau', startAt: '2026-11-25T18:00:00', version: 1, day: {} }] as never);
});
afterEach(() => { cleanup(); vi.clearAllMocks(); });

describe('DashboardPage – Hôm nay', () => {
  it('shows no action sections without module access', async () => {
    show({});
    expect(await screen.findByRole('heading', { name: /Hôm nay/ })).toBeInTheDocument();
    expect(screen.queryByRole('region', { name: 'Việc hôm nay' })).not.toBeInTheDocument();
    expect(screen.queryByRole('region', { name: 'Chi tiêu' })).not.toBeInTheDocument();
    expect(getTodos).not.toHaveBeenCalled();
    expect(getFinanceDashboard).not.toHaveBeenCalled();
  });

  it('shows every section for admins even when saved flags are false', async () => {
    show({ role: 'ADMIN' });
    for (const name of ['Việc hôm nay', 'Thói quen', 'Bữa ăn hôm nay', 'Buổi tập hôm nay', 'Chi tiêu']) {
      expect(await screen.findByRole('region', { name })).toBeInTheDocument();
    }
    expect(await screen.findByRole('link', { name: /Bắt đầu/ })).toHaveAttribute('href', '/workouts?appointment=a1');
  });

  it('lists overdue todos first and completes one inline', async () => {
    show({ todoEnabled: true });
    const section = await screen.findByRole('region', { name: 'Việc hôm nay' });
    const items = await within(section).findAllByRole('listitem');
    expect(items[0]).toHaveTextContent('Nộp báo cáo');
    expect(items[0]).toHaveTextContent('Quá hạn');
    fireEvent.click(within(section).getByRole('button', { name: 'Hoàn thành Đi chợ' }));
    await waitFor(() => expect(completeTodo).toHaveBeenCalledWith('t2'));
  });

  it('shows only unmarked habits and checks one in', async () => {
    show({ todoEnabled: true });
    const section = await screen.findByRole('region', { name: 'Thói quen' });
    expect(await within(section).findByText('Uống nước')).toBeInTheDocument();
    expect(within(section).queryByText('Đọc sách')).not.toBeInTheDocument();
    expect(within(section).getByText('Đã đánh dấu 1/2')).toBeInTheDocument();
    fireEvent.click(within(section).getByRole('button', { name: 'Đã làm Uống nước' }));
    await waitFor(() => expect(personalTrackingApi.checkin).toHaveBeenCalledWith('/todos/habits', 'h1', expect.any(String), { status: 'DONE' }));
  });

  it('opens quick add on the missing meal', async () => {
    show({ healthEnabled: true });
    const section = await screen.findByRole('region', { name: 'Bữa ăn hôm nay' });
    expect(await within(section).findByText('Thiếu 2 bữa')).toBeInTheDocument();
    fireEvent.click(within(section).getByRole('button', { name: 'Ghi bữa tối' }));
    const dialog = await screen.findByRole('dialog');
    expect(within(dialog).getByLabelText('Bữa')).toHaveValue('DINNER');
  });

  it('keeps other sections working when finance fails', async () => {
    vi.mocked(getFinanceDashboard).mockRejectedValue(new Error('down'));
    vi.mocked(getFinanceTransactions).mockRejectedValue(new Error('down'));
    show({ todoEnabled: true, financeEnabled: true });
    const finance = await screen.findByRole('region', { name: 'Chi tiêu' });
    expect(await within(finance).findByText('Không tải được thu chi.')).toBeInTheDocument();
    expect(within(finance).getByRole('button', { name: /Thử lại/ })).toBeInTheDocument();
    const todos = screen.getByRole('region', { name: 'Việc hôm nay' });
    expect(await within(todos).findByText('Đi chợ')).toBeInTheDocument();
  });

  it('sums only posted expenses for today', async () => {
    show({ financeEnabled: true });
    const finance = await screen.findByRole('region', { name: 'Chi tiêu' });
    expect(await within(finance).findByText('1 khoản chi')).toBeInTheDocument();
    expect(within(finance).getByText(/50\.000/)).toBeInTheDocument();
  });
});
