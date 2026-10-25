import { cleanup, render, screen } from '@testing-library/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { MemoryRouter } from 'react-router-dom';
import { afterEach, describe, expect, it, vi } from 'vitest';
import DashboardPage from './DashboardPage';
import { useAuthStore, type AuthUser } from '@/store/auth.store';

vi.mock('../api/dashboard.api', () => ({
  getTodayDashboard: vi.fn().mockResolvedValue({ fitnessEnabled: false, healthEnabled: false, lunchEnabled: false, todoEnabled: false, scheduleEnabled: false, quoteEnabled: false, financeEnabled: false, agenda: [] }),
  getProgressDashboard: vi.fn().mockResolvedValue({ points: [] }),
}));
vi.mock('../api/recommendation.api', () => ({ getWeeklyRecommendations: vi.fn().mockResolvedValue(null) }));
vi.mock('../api/achievement.api', () => ({ getAchievementSummary: vi.fn().mockResolvedValue(null) }));
vi.mock('../api/finance.api', () => ({ getFinanceDashboard: vi.fn().mockResolvedValue(null) }));
vi.mock('../components/MacroProgressCard', () => ({ default: () => null }));
vi.mock('../components/DeferredFitnessTrendCharts', () => ({ default: () => null }));
vi.mock('../components/quotes/DailyQuoteCard', () => ({ default: () => null }));

function show(role: 'ADMIN' | 'USER') {
  useAuthStore.setState({ user: { userId: 'test', role } as AuthUser });
  render(<QueryClientProvider client={new QueryClient({ defaultOptions: { queries: { retry: false } } })}><MemoryRouter><DashboardPage /></MemoryRouter></QueryClientProvider>);
}

afterEach(cleanup);
describe('Dashboard quick-entry permissions', () => {
  it('hides quick forms for users without module access', async () => {
    show('USER');
    await screen.findByText('Tổng quan hôm nay');
    expect(screen.queryByRole('link', { name: 'Ghi chi tiêu' })).not.toBeInTheDocument();
    expect(screen.queryByRole('link', { name: 'Thêm việc' })).not.toBeInTheDocument();
  });
  it('allows admins even when saved flags are false', async () => {
    show('ADMIN');
    expect(await screen.findByRole('link', { name: 'Ghi chi tiêu' })).toHaveAttribute('href', '/finance?action=new');
    expect(screen.getByRole('link', { name: 'Thêm việc' })).toHaveAttribute('href', '/todos?action=new');
    expect(screen.getByRole('link', { name: 'Bắt đầu tập' })).toHaveAttribute('href', '/workouts?action=new');
  });
});
