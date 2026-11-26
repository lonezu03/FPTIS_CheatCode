import { describe, expect, it } from "vitest";
import {
  CHORD_CHANGE_PAIRS,
  CHORD_INTERVALS,
  CHORDS,
  chordPitchClasses,
  findChord,
  fingerPatternTab,
  lowestPlayedString,
  nearestGuitarString,
  oneMinuteExerciseKey,
  parseOneMinuteKey,
  STANDARD_TUNING_MIDI,
  STRUM_PATTERNS,
} from "./guitar-data";

const cases = CHORDS.map((chord) => [chord.name, chord] as const);

describe("chord library", () => {
  it.each(cases)("%s sounds only its chord tones and includes the root and third", (_name, chord) => {
    const allowed = CHORD_INTERVALS[chord.quality].map((interval) => (chord.root + interval) % 12);
    const sounded = chordPitchClasses(chord);
    expect(sounded.every((pc) => allowed.includes(pc))).toBe(true);
    expect(sounded).toContain(chord.root);
    expect(sounded).toContain(allowed[1]);
  });

  it.each(cases)("%s has a finger exactly on every fretted string and the root in the bass", (_name, chord) => {
    chord.frets.forEach((fret, index) => {
      const finger = chord.fingers[index];
      if (fret > 0) expect(finger).toBeGreaterThanOrEqual(1);
      else expect(finger).toBe(0);
      expect(finger).toBeLessThanOrEqual(4);
    });
    const lowest = chord.frets.findIndex((fret) => fret >= 0);
    expect((STANDARD_TUNING_MIDI[lowest] + chord.frets[lowest]) % 12).toBe(chord.root);
  });

  it("matches the well-known shapes", () => {
    expect(findChord("c")?.frets).toEqual([-1, 3, 2, 0, 1, 0]);
    expect(findChord("g")?.frets).toEqual([3, 2, 0, 0, 0, 3]);
    expect(findChord("d")?.frets).toEqual([-1, -1, 0, 2, 3, 2]);
    expect(findChord("am")?.frets).toEqual([-1, 0, 2, 2, 1, 0]);
    expect(findChord("f")?.barre).toEqual({ fret: 1, fromString: 1, toString: 2, finger: 1 });
    expect(lowestPlayedString(findChord("d")!)).toBe(4);
  });

  it("uses only known chords in the change pairs and builds valid exercise keys", () => {
    for (const [a, b] of CHORD_CHANGE_PAIRS) {
      expect(findChord(a)).toBeDefined();
      expect(findChord(b)).toBeDefined();
      expect(oneMinuteExerciseKey(a, b)).toMatch(/^[a-z0-9-]+$/);
    }
    expect(parseOneMinuteKey("guitar-one-minute-am-e")).toEqual(["am", "e"]);
    expect(parseOneMinuteKey("guitar-spider")).toBeNull();
  });

  it("has strum patterns that fill one 4/4 bar", () => {
    for (const pattern of STRUM_PATTERNS) expect(pattern.slots).toHaveLength(4 * pattern.subdivision);
  });

  it("writes finger exercise tab from string 6 to 1", () => {
    const tab = fingerPatternTab([1, 2, 3, 4], 5);
    expect(tab.map((row) => row.string)).toEqual([6, 5, 4, 3, 2, 1]);
    expect(tab[0].frets).toEqual([5, 6, 7, 8]);
  });
});

describe("tuner string targets", () => {
  it("picks the nearest open string", () => {
    expect(nearestGuitarString(80).note).toBe("E2");
    expect(nearestGuitarString(150).note).toBe("D3");
    expect(nearestGuitarString(250).note).toBe("B3");
    expect(nearestGuitarString(340).note).toBe("E4");
  });
});
