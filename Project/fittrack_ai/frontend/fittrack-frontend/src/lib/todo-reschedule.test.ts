import { describe, expect, it } from 'vitest';
import type { Todo } from '@/api/todo.api';
import { shiftedTodoDates } from './todo-reschedule';

const timed = { startAt: '2026-10-25T09:00:00', dueAt: '2026-10-26T12:00:00', reminderAt: '2026-10-25T08:30:00', reminderTimes: ['2026-10-24T18:00:00', '2026-10-26T11:00:00'] } as Todo;
describe('shiftedTodoDates', () => {
  it('preserves independent start, deadline and reminder offsets across month boundaries', () => {
    expect(shiftedTodoDates(timed, '2026-10-31')).toEqual({ startAt: '2026-10-31T09:00:00', dueAt: '2026-11-01T12:00:00', reminderAt: '2026-10-31T08:30:00', reminderTimes: ['2026-10-30T18:00:00', '2026-11-01T11:00:00'] });
  });
  it('uses deadline when no start exists without creating a start', () => {
    expect(shiftedTodoDates({ ...timed, startAt: null }, '2026-11-01')?.startAt).toBeNull();
    expect(shiftedTodoDates({ ...timed, startAt: null }, '2026-11-01')?.dueAt).toBe('2026-11-01T12:00:00');
  });
  it('schedules an untimed task without inventing reminders or deadlines', () => {
    expect(shiftedTodoDates({ ...timed, startAt: null, dueAt: null }, '2026-11-01')).toEqual({ startAt: '2026-11-01T09:00:00' });
  });
  it('rejects impossible calendar dates and malformed input', () => {
    expect(shiftedTodoDates(timed, '2026-02-30')).toBeNull();
    expect(shiftedTodoDates(timed, '')).toBeNull();
  });
});
