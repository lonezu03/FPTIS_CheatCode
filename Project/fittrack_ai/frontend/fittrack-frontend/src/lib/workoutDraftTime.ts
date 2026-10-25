// Backend accepts at most 600 minutes. Recovery uses recorded elapsed time,
// never wall time since a browser that may have been closed for several days.
export const maximumWorkoutSeconds = 600 * 60;

export function workoutElapsedSeconds(recorded: number, activeSince: number, now: number): number {
  const safeRecorded = Number.isFinite(recorded) ? Math.max(0, recorded) : 0;
  const active = Math.max(0, Math.floor((now - activeSince) / 1000));
  return Math.min(maximumWorkoutSeconds, Math.floor(safeRecorded + active));
}
