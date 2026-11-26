import { describe, expect, it } from "vitest";
import { clampBpm, tapTempo, tickAt, tickInterval } from "./metronome-engine";

describe("metronome logic", () => {
  it("clamps tempo to 40..208", () => {
    expect(clampBpm(10)).toBe(40);
    expect(clampBpm(300)).toBe(208);
    expect(clampBpm(Number.NaN)).toBe(60);
    expect(tickInterval(120)).toBeCloseTo(0.5);
    expect(tickInterval(60, 2)).toBeCloseTo(0.5);
  });

  it("accents only the first tick of the bar", () => {
    expect(tickAt(0, 4, 1)).toMatchObject({ beat: 0, sub: 0, accent: true });
    expect(tickAt(3, 4, 1)).toMatchObject({ beat: 3, accent: false });
    expect(tickAt(4, 4, 1).accent).toBe(true);
    expect(tickAt(3, 3, 2)).toMatchObject({ beat: 1, sub: 1, accent: false });
    expect(tickAt(6, 3, 2).accent).toBe(true);
  });

  it("computes tap tempo and restarts after a pause", () => {
    expect(tapTempo([0]).bpm).toBeNull();
    expect(tapTempo([0, 500, 1000, 1500]).bpm).toBe(120);
    const afterPause = tapTempo([0, 500, 5000, 6000]);
    expect(afterPause.taps).toEqual([5000, 6000]);
    expect(afterPause.bpm).toBe(60);
    expect(tapTempo([0, 100, 200]).bpm).toBe(208);
  });
});
