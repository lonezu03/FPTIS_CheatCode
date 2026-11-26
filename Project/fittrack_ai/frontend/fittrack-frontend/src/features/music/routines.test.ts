import { describe, expect, it } from "vitest";
import { buildRoutine, dayNumber, ROUTINE_LENGTHS, suggestBpm } from "./routines";
import { EXERCISE_KEY_PATTERN, exerciseLabel, EXERCISES } from "./exercises";

const combos = ROUTINE_LENGTHS.flatMap((length) => (["GUITAR", "FLUTE"] as const).map((instrument) => [instrument, length] as const));

describe("daily routine", () => {
  it.each(combos)("%s %s-minute routine adds up and uses valid keys", (instrument, length) => {
    for (let day = 0; day < 14; day++) {
      const routine = buildRoutine(instrument, length, day);
      expect(routine.totalMinutes).toBe(length);
      expect(routine.steps).toHaveLength(4);
      for (const step of routine.steps) {
        expect(step.exerciseKey).toMatch(EXERCISE_KEY_PATTERN);
        expect(EXERCISES.some((exercise) => exercise.key === step.exerciseKey)).toBe(true);
        expect(step.how.length).toBeGreaterThan(0);
      }
    }
  });

  it("follows warm-up → technique → chord change → strumming for guitar", () => {
    const keys = buildRoutine("GUITAR", 15, 0).steps.map((step) => step.exerciseKey);
    expect(keys[0]).toBe("guitar-warmup");
    expect(keys[2]).toBe("guitar-chord-change");
    expect(keys[3]).toBe("guitar-strumming");
  });

  it("rotates the chord pair from day to day", () => {
    expect(buildRoutine("GUITAR", 15, 0).steps[2].title).not.toBe(buildRoutine("GUITAR", 15, 1).steps[2].title);
  });

  it("suggests 5 BPM over the best clean tempo", () => {
    const best = [{ exerciseKey: "guitar-spider", instrument: "GUITAR" as const, bpm: 72, practicedOn: "2026-11-20" }];
    expect(suggestBpm("guitar-spider", best, 60)).toBe(77);
    expect(suggestBpm("flute-scale", best, 60)).toBe(60);
  });

  it("counts days in local time", () => {
    expect(dayNumber(new Date(2026, 0, 2)) - dayNumber(new Date(2026, 0, 1))).toBe(1);
    expect(dayNumber(new Date(2026, 0, 1, 23, 59))).toBe(dayNumber(new Date(2026, 0, 1, 0, 1)));
  });

  it("labels known and one-minute exercises", () => {
    expect(exerciseLabel("flute-long-tones")).toBe("Ngân dài");
    expect(exerciseLabel("guitar-one-minute-am-e")).toBe("Đổi hợp âm 1 phút: Am ↔ E");
    expect(exerciseLabel("guitar-one-minute-c-f")).toBe("Đổi hợp âm 1 phút: C ↔ F");
  });
});
