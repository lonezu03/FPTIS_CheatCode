import { describe, expect, it } from "vitest";
import { detectPitch, median } from "./pitch-detection";
import { centsBetween, nearestNote } from "./music-theory";

const RATE = 44100;

function tone(frequency: number, harmonics: number[] = [1], size = 4096, rate = RATE) {
  const buffer = new Float32Array(size);
  for (let i = 0; i < size; i++) {
    let value = 0;
    harmonics.forEach((amplitude, index) => {
      value += amplitude * Math.sin((2 * Math.PI * frequency * (index + 1) * i) / rate);
    });
    buffer[i] = 0.3 * value;
  }
  return buffer;
}

describe("detectPitch", () => {
  it.each([82.41, 110, 146.83, 196, 246.94, 329.63, 440, 523.25, 987.77, 1567.98])("detects a pure %s Hz tone within 5 cents", (frequency) => {
    const result = detectPitch(tone(frequency), RATE);
    expect(result).not.toBeNull();
    expect(Math.abs(centsBetween(result!.frequency, frequency))).toBeLessThan(5);
  });

  it("keeps the fundamental of a harmonic-rich low E string (no octave error)", () => {
    const result = detectPitch(tone(82.41, [0.6, 1, 0.8, 0.5, 0.3]), RATE);
    expect(nearestNote(result!.frequency).label).toBe("E2");
  });

  it("works at 48 kHz", () => {
    const result = detectPitch(tone(523.25, [1, 0.3], 4096, 48000), 48000);
    expect(nearestNote(result!.frequency).label).toBe("C5");
  });

  it("returns null for silence and for noise", () => {
    expect(detectPitch(new Float32Array(4096), RATE)).toBeNull();
    let seed = 7;
    const noise = new Float32Array(4096).map(() => {
      seed = (seed * 16807) % 2147483647;
      return (seed / 2147483647 - 0.5) * 0.5;
    });
    expect(detectPitch(noise, RATE)).toBeNull();
  });

  it("median smooths readings", () => {
    expect(median([])).toBeNull();
    expect(median([3, 1, 2])).toBe(2);
    expect(median([4, 1, 2, 3])).toBe(2.5);
  });
});
