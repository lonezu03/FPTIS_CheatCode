import type { Todo, TodoPayload } from '@/api/todo.api';

/** Move the calendar date, retaining wall-clock time and each independent offset. */
export function shiftedTodoDates(todo: Todo, targetDay: string): Partial<TodoPayload> | null {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(targetDay)) return null;
  const target = Date.parse(targetDay);
  if (!Number.isFinite(target) || new Date(target).toISOString().slice(0, 10) !== targetDay) return null;
  const anchor = todo.startAt ?? todo.dueAt;
  if (!anchor) return { startAt: `${targetDay}T09:00:00` };
  const delta = target - Date.parse(anchor.slice(0, 10));
  const shift = (value: string | null) => value ? new Date(Date.parse(value.slice(0, 10)) + delta).toISOString().slice(0, 10) + value.slice(10) : null;
  return { startAt: shift(todo.startAt), dueAt: shift(todo.dueAt), reminderAt: shift(todo.reminderAt), reminderTimes: todo.reminderTimes.map(value => shift(value)!) };
}
