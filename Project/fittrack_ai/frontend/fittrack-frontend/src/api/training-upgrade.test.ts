import { beforeEach, describe, expect, it, vi } from 'vitest';
import api from './axios';
import { getWorkoutSessionsPage, replaceWorkoutSession } from './workout.api';
import { getWorkoutPlanDetail, updateWorkoutPlan } from './workout-plan.api';
vi.mock('./axios', () => ({ default: { get: vi.fn(), put: vi.fn() } }));

describe('training history and prescriptions contracts', () => {
  beforeEach(() => vi.resetAllMocks());
  it('sends date and exercise filters to server history pagination', async () => {
    vi.mocked(api.get).mockResolvedValue({ data: { content: [], totalElements: 0 } });
    await getWorkoutSessionsPage(2, 12, { from: '2026-10-01', to: '2026-10-25', exerciseId: 'exercise' });
    expect(api.get).toHaveBeenCalledWith('/workouts/sessions/history', { params: { page: 2, size: 12, from: '2026-10-01', to: '2026-10-25', exerciseId: 'exercise' } });
  });
  it('uses full replacement endpoint without reducing a multi-set payload', async () => {
    const set = { exerciseId: 'exercise', exerciseOrder: 1, setNumber: 1, setType: 'NORMAL' as const, weight: 20, reps: 10, rir: 2, restSeconds: 90, completed: true };
    const payload = { sessionDate: '2026-10-25', durationMinutes: 45, note: 'Updated', sets: [set, { ...set, setNumber: 2, weight: 25, restSeconds: 180 }] };
    vi.mocked(api.put).mockResolvedValue({ data: payload });
    await replaceWorkoutSession('session', payload);
    expect(api.put).toHaveBeenCalledWith('/workouts/sessions/session/details', payload);
  });
  it('retains optimistic plan version and prescription fields', async () => {
    vi.mocked(api.get).mockResolvedValue({ data: { id: 'plan', version: 4 } });
    expect((await getWorkoutPlanDetail('plan')).version).toBe(4);
    const payload = { version: 4, name: 'Plan', description: '', days: [{ name: 'Day', dayOrder: 1, exercises: [{ exerciseId: 'exercise', exerciseOrder: 1, targetSets: 3, targetReps: 10, targetWeight: 20, targetRir: 2, minReps: 8, maxReps: 12, restSeconds: 120, coachingNote: 'Slow eccentric' }] }] };
    vi.mocked(api.put).mockResolvedValue({ data: payload });
    await updateWorkoutPlan('plan', payload);
    expect(api.put).toHaveBeenCalledWith('/workout-plans/plan', payload);
  });
});
