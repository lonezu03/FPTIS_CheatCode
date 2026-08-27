import api from './axios';
export type Todo = { id:string; title:string; description:string|null; status:'OPEN'|'IN_PROGRESS'|'DONE'|'ARCHIVED'; priority:'LOW'|'MEDIUM'|'HIGH'; dueAt:string|null; reminderAt:string|null; reminderEnabled:boolean; createdAt:string; updatedAt:string };
export type TodoPayload = { title:string; description?:string; status?:Todo['status']; priority?:Todo['priority']; dueAt?:string|null; reminderAt?:string|null; reminderEnabled?:boolean };
export const getTodos = async () => (await api.get<Todo[]>('/todos')).data;
export const createTodo = async (payload:TodoPayload) => (await api.post<Todo>('/todos', payload)).data;
export const updateTodo = async (id:string, payload:TodoPayload) => (await api.patch<Todo>(`/todos/${id}`, payload)).data;
export const deleteTodo = async (id:string) => { await api.delete(`/todos/${id}`); };
