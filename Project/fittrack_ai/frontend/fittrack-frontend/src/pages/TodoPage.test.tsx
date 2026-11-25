import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { cleanup, fireEvent, render, screen, waitFor } from '@testing-library/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { MemoryRouter } from 'react-router-dom';
import { toast } from 'sonner';
import TodoPage from './TodoPage';
import { completeTodo, getTodo, getTodoPage, updateTodo, type Todo } from '@/api/todo.api';

vi.mock('sonner', () => ({ toast: { success: vi.fn(), info: vi.fn(), error: vi.fn() } }));
vi.mock('@/api/todo.api', () => ({
  getTodoPage: vi.fn(), getTodo: vi.fn(), completeTodo: vi.fn(), updateTodo: vi.fn(),
  createTodo: vi.fn(), deleteTodo: vi.fn(), skipTodo: vi.fn(), snoozeTodo: vi.fn(), getTodos: vi.fn(),
}));

const base: Todo = {
  id: 't1', title: 'Nộp báo cáo', description: null, status: 'IN_PROGRESS', priority: 'MEDIUM', startAt: null, dueAt: null,
  estimatedMinutes: null, category: 'WORK', recurrenceRule: 'NONE', recurrenceInterval: 1, daysOfWeek: [], recurrenceBasis: 'SCHEDULED_DATE',
  recurrenceEndAt: null, recurrenceMaxOccurrences: null, occurrenceNumber: 1, completedAt: null, skippedAt: null, reminderAt: null,
  reminderEnabled: false, recurringSeriesId: null, subtasks: [], createdAt: '2026-11-25T08:00:00', updatedAt: '2026-11-25T08:00:00', reminderTimes: [],
};
const done: Todo = { ...base, status: 'DONE', completedAt: '2026-11-25T09:00:00', updatedAt: '2026-11-25T09:00:00' };

function show() {
  render(<QueryClientProvider client={new QueryClient({ defaultOptions: { queries: { retry: false }, mutations: { retry: false } } })}><MemoryRouter><TodoPage /></MemoryRouter></QueryClientProvider>);
}

function clickUndo() {
  // Action của sonner nhận MouseEvent; handler của TodoPage không dùng tham số này.
  const action = vi.mocked(toast.success).mock.calls[0][1]?.action as unknown as { onClick: () => void };
  action.onClick();
}

beforeEach(() => {
  vi.mocked(getTodoPage).mockResolvedValue({ content: [base], totalElements: 1, totalPages: 1, number: 0, size: 20, counts: { today: 1, overdue: 0, upcoming: 0, done: 0, all: 1 } });
  vi.mocked(completeTodo).mockResolvedValue(done);
  vi.mocked(getTodo).mockResolvedValue(done);
  vi.mocked(updateTodo).mockResolvedValue(base);
});
afterEach(() => { cleanup(); vi.clearAllMocks(); });

describe('Todo hoàn tác', () => {
  it('sau khi hoàn thành, nút Hoàn tác trả công việc về trạng thái trước đó', async () => {
    show();
    fireEvent.click(await screen.findByRole('button', { name: 'Đánh dấu hoàn thành' }));
    await waitFor(() => expect(toast.success).toHaveBeenCalledWith('Đã hoàn thành công việc', expect.objectContaining({ action: expect.objectContaining({ label: 'Hoàn tác' }) })));
    clickUndo();
    await waitFor(() => expect(updateTodo).toHaveBeenCalledWith('t1', expect.objectContaining({ status: 'IN_PROGRESS' })));
    await waitFor(() => expect(toast.success).toHaveBeenCalledWith('Đã hoàn tác', expect.anything()));
  });

  it('không hoàn tác khi công việc đã đổi ở nơi khác', async () => {
    vi.mocked(getTodo).mockResolvedValue({ ...done, updatedAt: '2026-11-25T10:00:00' });
    show();
    fireEvent.click(await screen.findByRole('button', { name: 'Đánh dấu hoàn thành' }));
    await waitFor(() => expect(toast.success).toHaveBeenCalled());
    clickUndo();
    await waitFor(() => expect(toast.info).toHaveBeenCalledWith('Công việc đã thay đổi; hãy kiểm tra lại.'));
    expect(updateTodo).not.toHaveBeenCalled();
  });
});
