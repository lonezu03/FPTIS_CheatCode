import { describe, expect, it } from "vitest";
import { maximumWorkoutSeconds, workoutElapsedSeconds } from "./workoutDraftTime";

describe("workout draft duration", () => {
  it("adds only active time after recovery, not the days the browser was closed", () => {
    const reopenedAt = Date.UTC(2026, 9, 28);
    expect(workoutElapsedSeconds(1800, reopenedAt, reopenedAt + 60000)).toBe(1860);
  });
  it("bounds long open sessions to the backend's 600 minute limit", () => {
    expect(workoutElapsedSeconds(100, 0, 3 * 24 * 60 * 60 * 1000)).toBe(maximumWorkoutSeconds);
    expect(workoutElapsedSeconds(Number.NaN, 1000, 0)).toBe(0);
  });
});
