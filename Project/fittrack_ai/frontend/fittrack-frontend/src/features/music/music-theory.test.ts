import { describe, expect, it } from "vitest";
import { centsBetween, midiToFrequency, nearestNote, noteToFrequency, noteToMidi, tuneState } from "./music-theory";

describe("music theory", () => {
  it("uses A4 = 440 Hz equal temperament", () => {
    expect(noteToFrequency("A4")).toBeCloseTo(440, 6);
    expect(noteToFrequency("C5")).toBeCloseTo(523.2511, 3);
    expect(noteToFrequency("E2")).toBeCloseTo(82.4069, 3);
    expect(noteToFrequency("E4")).toBeCloseTo(329.6276, 3);
  });

  it("parses note names and rejects junk", () => {
    expect(noteToMidi("C5")).toBe(72);
    expect(noteToMidi("F#3")).toBe(54);
    expect(noteToMidi("H2")).toBeNull();
  });

  it("finds the nearest note with cents and solfège", () => {
    const flat = nearestNote(midiToFrequency(72) * 2 ** (-10 / 1200));
    expect(flat.label).toBe("C5");
    expect(flat.solfege).toBe("Đô");
    expect(flat.cents).toBeCloseTo(-10, 6);
    expect(nearestNote(110).label).toBe("A2");
    expect(nearestNote(1975.5).label).toBe("B6");
  });

  it("classifies tuning distance", () => {
    expect(tuneState(3)).toBe("in-tune");
    expect(tuneState(-12)).toBe("close");
    expect(tuneState(-40)).toBe("low");
    expect(tuneState(40)).toBe("high");
    expect(centsBetween(880, 440)).toBeCloseTo(1200, 6);
  });
});
