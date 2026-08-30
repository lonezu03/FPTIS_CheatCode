import api from './axios';

export type TodoStatus = 'OPEN' | 'IN_PROGRESS' | 'DONE' | 'ARCHIVED' | 'CANCELLED';
export type TodoPriority = 'LOW' | 'MEDIUM' | 'HIGH';
export type TodoCategory = 'WORK' | 'STUDY' | 'PERSONAL' | 'HEALTH' | 'FINANCE' | 'SHOPPING';
export type TodoRecurrence = 'NONE' | 'DAILY' | 'WEEKLY' | 'MONTHLY' | 'CUSTOM';

export type TodoSubtask = {
  id?: string | null;
  title: string;
  completed: boolean;
  sortOrder: number;
};

export type Todo = {
  id: string;
  title: string;
  description: string | null;
  status: TodoStatus;
  priority: TodoPriority;
  startAt: string | null;
  dueAt: string | null;
  estimatedMinutes: number | null;
  category: TodoCategory;
  recurrenceRule: TodoRecurrence;
  recurrenceInterval: number;
  daysOfWeek: string[];
  reminderAt: string | null;
  reminderEnabled: boolean;
  recurringSeriesId: string | null;
  subtasks: TodoSubtask[];
  createdAt: string;
  updatedAt: string;
};

export type TodoPayload = {
  title: string;
  description?: string | null;
  status?: TodoStatus;
  priority?: TodoPriority;
  startAt?: string | null;
  dueAt?: string | null;
  estimatedMinutes?: number | null;
  category?: TodoCategory;
  recurrenceRule?: TodoRecurrence;
  recurrenceInterval?: number;
  daysOfWeek?: string;
  reminderAt?: string | null;
  reminderEnabled?: boolean;
  subtasks?: TodoSubtask[];
};

export type TodoQuery = {
  view?: 'ALL' | 'TODAY' | 'OVERDUE' | 'UPCOMING';
  category?: TodoCategory;
  status?: TodoStatus;
};

export const getTodos = async (query: TodoQuery = {}) =>
  (await api.get<Todo[]>('/todos', { params: query })).data;
export const createTodo = async (payload: TodoPayload) => (await api.post<Todo>('/todos', payload)).data;
export const updateTodo = async (id: string, payload: TodoPayload) => (await api.patch<Todo>(`/todos/${id}`, payload)).data;
export const deleteTodo = async (id: string) => { await api.delete(`/todos/${id}`); };
