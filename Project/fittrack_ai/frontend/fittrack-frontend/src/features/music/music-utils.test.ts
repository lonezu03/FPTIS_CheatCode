import { describe, expect, it } from "vitest";
import { formatClock, formatMinutes, oneMinuteResultBody, secondsToPracticeMinutes, toSessionInput, weekBars, weekdayLabel, type SessionForm } from "./music-utils";

const form = (overrides: Partial<SessionForm> = {}): SessionForm => ({
  instrument: "GUITAR",
  practicedOn: "2026-11-26",
  minutes: "15",
  exerciseKey: "guitar-spider",
  bpm: "",
  note: "",
  ...overrides,
});

describe("quick log form", () => {
  it("builds the API body", () => {
    expect(toSessionInput(form({ bpm: "72", note: "  sạch  " })).input).toEqual({
      instrument: "GUITAR",
      practicedOn: "2026-11-26",
      minutes: 15,
      exerciseKey: "guitar-spider",
      bpm: 72,
      note: "sạch",
    });
    expect(toSessionInput(form()).input?.bpm).toBeNull();
    expect(toSessionInput(form()).input?.note).toBeNull();
  });

  it("rejects values outside the contract", () => {
    expect(toSessionInput(form({ minutes: "0" })).errors.minutes).toBeTruthy();
    expect(toSessionInput(form({ minutes: "601" })).errors.minutes).toBeTruthy();
    expect(toSessionInput(form({ minutes: "2.5" })).errors.minutes).toBeTruthy();
    expect(toSessionInput(form({ bpm: "19" })).errors.bpm).toBeTruthy();
    expect(toSessionInput(form({ bpm: "301" })).errors.bpm).toBeTruthy();
    expect(toSessionInput(form({ exerciseKey: "Guitar Spider" })).errors.exerciseKey).toBeTruthy();
    expect(toSessionInput(form({ note: "a".repeat(501) })).errors.note).toBeTruthy();
  });

  it("stores a one-minute count as BPM only when the API accepts it", () => {
    expect(oneMinuteResultBody(25)).toEqual({ bpm: 25, note: "25 lần đổi trong 1 phút" });
    expect(oneMinuteResultBody(12).bpm).toBeNull();
  });
});

describe("display helpers", () => {
  it("scales week bars to the busiest day with a 20-minute floor", () => {
    const { bars, max } = weekBars([
      { date: "2026-11-23", guitarMinutes: 10, fluteMinutes: 0 },
      { date: "2026-11-24", guitarMinutes: 15, fluteMinutes: 25 },
    ]);
    expect(max).toBe(40);
    expect(bars[0]).toMatchObject({ total: 10, label: "T2", guitarPct: 25 });
    expect(bars[1].flutePct).toBeCloseTo(62.5);
    expect(weekBars([{ date: "2026-11-29", guitarMinutes: 5, fluteMinutes: 0 }]).max).toBe(20);
    expect(weekdayLabel("2026-11-29")).toBe("CN");
  });

  it("formats durations", () => {
    expect(formatMinutes(45)).toBe("45 phút");
    expect(formatMinutes(60)).toBe("1 giờ");
    expect(formatMinutes(75)).toBe("1 giờ 15 phút");
    expect(formatClock(65)).toBe("01:05");
    expect(formatClock(0.2)).toBe("00:01");
    expect(secondsToPracticeMinutes(20)).toBe(1);
    expect(secondsToPracticeMinutes(14 * 60 + 40)).toBe(15);
  });
});
