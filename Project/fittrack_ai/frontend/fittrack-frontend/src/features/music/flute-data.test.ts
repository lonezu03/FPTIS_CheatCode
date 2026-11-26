import { describe, expect, it } from "vitest";
import { FLUTE_BASE_HZ, FLUTE_NOTES, FLUTE_SONGS, findFluteNote, nextLongToneTarget, pickNextNote, scaleSequence } from "./flute-data";
import { noteToMidi } from "./music-theory";

const covered = (key: string) =>
  findFluteNote(key)!
    .covered.map((hole) => (hole ? 1 : 0))
    .join("");

describe("sáo Đô (C5) fingering", () => {
  it("follows the 6-hole convention, holes numbered from the mouth-hole end", () => {
    expect(covered("do")).toBe("111111");
    expect(covered("re")).toBe("111110");
    expect(covered("mi")).toBe("111100");
    expect(covered("fa")).toBe("111000");
    expect(covered("sol")).toBe("110000");
    expect(covered("la")).toBe("100000");
    expect(covered("si")).toBe("000000");
  });

  it("uses the same fingering one octave higher", () => {
    for (const note of FLUTE_NOTES.filter((item) => item.register === "high")) {
      const low = findFluteNote(note.key.replace("-cao", ""))!;
      expect(note.covered).toEqual(low.covered);
      expect(noteToMidi(note.note)! - noteToMidi(low.note)!).toBe(12);
    }
  });

  it("starts at C5 = 523.25 Hz", () => {
    expect(FLUTE_BASE_HZ).toBeCloseTo(523.25, 2);
    expect(findFluteNote("do")!.note).toBe("C5");
  });

  it("goes up to high Đô and back down", () => {
    const keys = scaleSequence().map((note) => note.key);
    expect(keys[0]).toBe("do");
    expect(keys[7]).toBe("do-cao");
    expect(keys.at(-1)).toBe("do");
    expect(keys).toHaveLength(15);
  });

  it("grows the long-tone target on success and eases it after two misses", () => {
    expect(nextLongToneTarget(6, 6.2)).toEqual({ target: 7, success: true, missesInRow: 0 });
    expect(nextLongToneTarget(6, 4, 0)).toEqual({ target: 6, success: false, missesInRow: 1 });
    expect(nextLongToneTarget(6, 4, 1)).toEqual({ target: 5, success: false, missesInRow: 0 });
    expect(nextLongToneTarget(30, 40).target).toBe(30);
    expect(nextLongToneTarget(4, 1, 1).target).toBe(4);
  });

  it("never repeats the previous note in the reading drill", () => {
    const pool = FLUTE_NOTES.slice(0, 3);
    for (let i = 0; i < 20; i++) expect(pickNextNote(pool, "do", () => i / 20).key).not.toBe("do");
  });

  it("keeps songs inside the playable Đô–La range", () => {
    const allowed = new Set(["Đô", "Rê", "Mi", "Fa", "Sol", "La", "–", "|"]);
    for (const song of FLUTE_SONGS) {
      for (const token of song.lines.join(" ").split(/\s+/)) expect(allowed.has(token)).toBe(true);
    }
  });
});
