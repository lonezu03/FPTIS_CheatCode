import { cleanup, fireEvent, render, screen, waitFor, within } from '@testing-library/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { MemoryRouter } from 'react-router-dom';
import { afterEach, describe, expect, it, vi } from 'vitest';
import { useAuthStore, type AuthUser } from '@/store/auth.store';
import { createTodo } from '@/api/todo.api';
import { createFinanceTransaction } from '@/api/finance.api';
import { createBodyMeasurement } from '@/api/body.api';
import { QuickAddButton } from './QuickAddButton';
import { allowedQuickAddTabs, isQuickAddShortcut, mealQuantity, mealTypeForHour } from './quick-add-config';
import { parseMoney, validateBody, validateFinance, validateJournal, validateTodo } from './quick-add-validation';

vi.mock('@/api/todo.api', () => ({ createTodo: vi.fn() }));
vi.mock('@/api/body.api', () => ({ createBodyMeasurement: vi.fn() }));
vi.mock('@/api/finance.api', () => ({
  getFinanceAccounts: vi.fn().mockResolvedValue([{ id: 'acc', name: 'Ví', active: true }]),
  getFinanceCategories: vi.fn().mockResolvedValue([
    { id: 'food', name: 'Ăn uống', transactionKind: 'EXPENSE', active: true, parentId: null },
    { id: 'salary', name: 'Lương', transactionKind: 'INCOME', active: true, parentId: null },
  ]),
  createFinanceTransaction: vi.fn(),
}));

const flags = { lunchEnabled: false, fitnessEnabled: false, healthEnabled: false, chatbotEnabled: false, todoEnabled: false, scheduleEnabled: false, quoteEnabled: false, financeEnabled: false, journalEnabled: false };
const user = (extra: Partial<AuthUser>) => ({ userId: 'u', role: 'USER', ...flags, ...extra }) as AuthUser;

function mount(extra: Partial<AuthUser>) {
  useAuthStore.setState({ user: user(extra) });
  return render(<QueryClientProvider client={new QueryClient({ defaultOptions: { queries: { retry: false } } })}><MemoryRouter><QuickAddButton /></MemoryRouter></QueryClientProvider>);
}

afterEach(() => { cleanup(); vi.clearAllMocks(); });

describe('quick-add rules', () => {
  it('filters tabs by feature and lets admins use all', () => {
    expect(allowedQuickAddTabs(user({ todoEnabled: true, healthEnabled: true })).map((tab) => tab.id)).toEqual(['todo', 'meal', 'body']);
    expect(allowedQuickAddTabs(user({ role: 'ADMIN' }))).toHaveLength(5);
    expect(allowedQuickAddTabs(null)).toHaveLength(0);
  });
  it('parses VND amounts', () => {
    expect(parseMoney('50k')).toBe(50_000);
    expect(parseMoney('1.250.000')).toBe(1_250_000);
    expect(parseMoney('35000')).toBe(35_000);
    expect(parseMoney('')).toBeNull();
    expect(parseMoney('12a')).toBeNaN();
  });
  it('validates each form', () => {
    const now = new Date('2026-11-25T10:00:00');
    expect(validateTodo({ title: ' ', dueAt: '' }, now).title).toBeTruthy();
    expect(validateTodo({ title: 'A', dueAt: '2026-11-24T10:00' }, now).dueAt).toBe('Hạn đã qua.');
    expect(validateTodo({ title: 'A', dueAt: '2026-11-25T23:59' }, now)).toEqual({});
    expect(validateFinance({ amount: '0', accountId: '', categoryId: '', note: '' })).toMatchObject({ amount: expect.any(String), accountId: expect.any(String), categoryId: expect.any(String) });
    expect(validateBody({ weight: '5', waist: '', recordDate: '2026-11-25' }, '2026-11-25').weight).toBeTruthy();
    expect(validateBody({ weight: '65,5', waist: '', recordDate: '2026-11-26' }, '2026-11-25')).toEqual({ recordDate: 'Không chọn ngày tương lai.' });
    expect(validateJournal({ title: '', body: '' }).body).toBeTruthy();
  });
  it('converts grams to servings and picks a meal by hour', () => {
    expect(mealQuantity(150, 'GRAM', 100)).toBe(1.5);
    expect(mealQuantity(2, 'SERVING', 100)).toBe(2);
    expect(mealTypeForHour(7)).toBe('BREAKFAST');
    expect(mealTypeForHour(19)).toBe('DINNER');
  });
  it('recognises Alt+N only', () => {
    const base = { altKey: true, ctrlKey: false, metaKey: false, shiftKey: false, repeat: false, code: 'KeyN' };
    expect(isQuickAddShortcut(base)).toBe(true);
    expect(isQuickAddShortcut({ ...base, ctrlKey: true })).toBe(false);
    expect(isQuickAddShortcut({ ...base, code: 'KeyM' })).toBe(false);
  });
});

describe('QuickAddButton', () => {
  it('renders nothing without any allowed module', () => {
    mount({ lunchEnabled: true });
    expect(screen.queryByRole('button', { name: /Ghi nhanh/ })).not.toBeInTheDocument();
  });

  it('opens with Alt+N and shows only allowed tabs', async () => {
    mount({ todoEnabled: true, financeEnabled: true });
    fireEvent.keyDown(window, { key: 'n', code: 'KeyN', altKey: true });
    const dialog = await screen.findByRole('dialog');
    expect(within(dialog).getAllByRole('tab').map((tab) => tab.textContent)).toEqual(['Việc', 'Thu/chi']);
  });

  it('validates and creates a todo', async () => {
    vi.mocked(createTodo).mockResolvedValue({ id: 't', title: 'Gọi mẹ' } as never);
    mount({ todoEnabled: true });
    fireEvent.click(screen.getByRole('button', { name: /Ghi nhanh/ }));
    const dialog = await screen.findByRole('dialog');
    fireEvent.click(within(dialog).getByRole('button', { name: 'Thêm việc' }));
    expect(await within(dialog).findByText('Nhập tên việc.')).toBeInTheDocument();
    expect(createTodo).not.toHaveBeenCalled();
    fireEvent.change(within(dialog).getByLabelText('Việc cần làm'), { target: { value: ' Gọi mẹ ' } });
    fireEvent.click(within(dialog).getByRole('button', { name: 'Thêm việc' }));
    await waitFor(() => expect(createTodo).toHaveBeenCalledWith(expect.objectContaining({ title: 'Gọi mẹ', priority: 'MEDIUM', dueAt: null })));
    await waitFor(() => expect(screen.queryByRole('dialog')).not.toBeInTheDocument());
  });

  it('records an expense with the only wallet preselected', async () => {
    vi.mocked(createFinanceTransaction).mockResolvedValue({ amount: 45_000 } as never);
    mount({ financeEnabled: true });
    fireEvent.click(screen.getByRole('button', { name: /Ghi nhanh/ }));
    const dialog = await screen.findByRole('dialog');
    fireEvent.change(await within(dialog).findByLabelText('Số tiền (đ)'), { target: { value: '45k' } });
    fireEvent.change(within(dialog).getByLabelText('Danh mục'), { target: { value: 'food' } });
    expect(within(dialog).queryByRole('option', { name: 'Lương' })).not.toBeInTheDocument();
    fireEvent.click(within(dialog).getByRole('button', { name: 'Ghi khoản chi' }));
    await waitFor(() => expect(createFinanceTransaction).toHaveBeenCalledWith(expect.objectContaining({
      type: 'EXPENSE', amount: 45_000, accountId: 'acc', categoryId: 'food', expenseNature: null,
    })));
  });

  it('keeps unmeasured body fields null', async () => {
    vi.mocked(createBodyMeasurement).mockResolvedValue({ weight: 66 } as never);
    mount({ healthEnabled: true });
    fireEvent.click(screen.getByRole('button', { name: /Ghi nhanh/ }));
    const dialog = await screen.findByRole('dialog');
    fireEvent.mouseDown(within(dialog).getByRole('tab', { name: 'Cân nặng' }));
    fireEvent.change(await within(dialog).findByLabelText('Cân nặng (kg)'), { target: { value: '66' } });
    fireEvent.click(within(dialog).getByRole('button', { name: 'Ghi cân nặng' }));
    await waitFor(() => expect(createBodyMeasurement).toHaveBeenCalledWith(expect.objectContaining({ weight: 66, waist: null, chest: null })));
  });
});
