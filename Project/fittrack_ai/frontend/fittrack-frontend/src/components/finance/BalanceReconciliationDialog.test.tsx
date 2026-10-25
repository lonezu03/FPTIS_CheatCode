import { cleanup, fireEvent, render, screen, waitFor } from '@testing-library/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import BalanceReconciliationDialog from './BalanceReconciliationDialog';
import { getFinanceAccounts, reconcileFinanceAccount, type FinanceAccount } from '@/api/finance.api';

vi.mock('@/api/finance.api', () => ({
  getFinanceAccounts: vi.fn(),
  getFinanceReconciliations: vi.fn().mockResolvedValue({ content: [], totalPages: 0, totalElements: 0 }),
  reconcileFinanceAccount: vi.fn(),
}));
const account: FinanceAccount = { id: 'wallet', name: 'Tiền mặt', active: true, accountType: 'CASH', currencyCode: 'VND', openingBalance: 1000000, currentBalance: 1000000 };
afterEach(cleanup);
beforeEach(() => { vi.clearAllMocks(); vi.mocked(getFinanceAccounts).mockResolvedValue([{ ...account, currentBalance: 100000 }]); });
function show() {
  const close = vi.fn();
  render(<QueryClientProvider client={new QueryClient({ defaultOptions: { queries: { retry: false }, mutations: { retry: false } } })}><BalanceReconciliationDialog account={account} onClose={close} /></QueryClientProvider>);
  return close;
}
describe('balance reconciliation', () => {
  it('requires actual money, a reason and confirmation; uses fresh balance and permits zero', async () => {
    const close = show();
    const actual = await screen.findByLabelText('Số dư thực tế (VND)');
    expect(reconcileFinanceAccount).not.toHaveBeenCalled();
    const save = screen.getByRole('button', { name: 'Xác nhận đối soát' });
    expect(save).toBeDisabled();
    fireEvent.change(actual, { target: { value: '0' } });
    fireEvent.change(screen.getByLabelText('Lý do điều chỉnh'), { target: { value: 'Kiểm tra tiền mặt' } });
    expect(save).toBeDisabled();
    fireEvent.click(screen.getByRole('checkbox'));
    expect(save).toBeEnabled();
    vi.mocked(reconcileFinanceAccount).mockResolvedValue({ id: 'audit', accountId: 'wallet', balanceBefore: 100000, balanceAfter: 0, difference: -100000, note: 'Kiểm tra tiền mặt', createdAt: '2026-10-25T12:00:00' });
    fireEvent.click(save);
    await waitFor(() => expect(close).toHaveBeenCalledOnce());
    expect(reconcileFinanceAccount).toHaveBeenCalledWith('wallet', { actualBalance: 0, expectedBalance: 100000, note: 'Kiểm tra tiền mặt' });
  });
  it('retains entered values after conflict and requires confirmation again', async () => {
    const close = show();
    const actual = await screen.findByLabelText('Số dư thực tế (VND)');
    fireEvent.change(actual, { target: { value: '250000' } });
    fireEvent.change(screen.getByLabelText('Lý do điều chỉnh'), { target: { value: 'Đối soát' } });
    fireEvent.click(screen.getByRole('checkbox'));
    vi.mocked(reconcileFinanceAccount).mockRejectedValue(new Error('Conflict'));
    vi.mocked(getFinanceAccounts).mockResolvedValue([{ ...account, currentBalance: 200000 }]);
    fireEvent.click(screen.getByRole('button', { name: 'Xác nhận đối soát' }));
    await waitFor(() => expect(screen.getByRole('checkbox')).not.toBeChecked());
    expect(actual).toHaveValue(250000);
    expect(close).not.toHaveBeenCalled();
    expect(screen.getByRole('button', { name: 'Xác nhận đối soát' })).toBeDisabled();
  });
});
